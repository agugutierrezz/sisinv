require "rails_helper"

RSpec.describe "API::V1::Articles (auto-transfer)", type: :request do
    let!(:user)    { create(:user) }
    let(:headers)  { { "Authorization" => "Bearer #{user.api_token}" } }

    let!(:marca)   { create(:brand) }
    let!(:modelo)  { create(:model, marca:) }
    let!(:p1)      { create(:person) }
    let!(:p2)      { create(:person) }

    def json_body
        JSON.parse(response.body) rescue {}
    end

    it "al crear artículo con persona_actual_id, crea automáticamente la PRIMERA transferencia abierta" do
        ingreso = "2025-09-01"
        post "/api/v1/articles",
            params: {
            articulo: {
                identificador: "ART-AUTO-001",
                modelo_id: modelo.id,
                fecha_ingreso: ingreso,
                persona_actual_id: p1.id
            }
            },
            headers: headers

        expect(response).to have_http_status(:created)

        art_id = json_body["id"] || json_body.dig("data", "id")
        expect(art_id).to be_present

        t = Transferencia.where(articulo_id: art_id, persona_id: p1.id).order(:id).last
        expect(t).to be_present
        expect(t.fecha_fin).to be_nil
        expect(t.fecha_inicio.to_date).to eq(Date.parse(ingreso))
        expect(Articulo.find(art_id).persona_actual_id).to eq(p1.id)
    end

    it "al actualizar el artículo sin portador, crea la asignación inicial; si ya tenía, devuelve 422 y pide transferencia" do
    # 1) Crear sin portador
    ident  = "ART-AUTO-002"
    ingreso = "2025-09-01"
    post "/api/v1/articles",
        params: { articulo: { identificador: ident, modelo_id: modelo.id, fecha_ingreso: ingreso } },
        headers: headers
    art_id = json_body["id"] || json_body.dig("data","id")

    # 2) Primera asignación desde edición (permitida) → fecha_inicio = Time.current
    put "/api/v1/articles/#{art_id}",
        params: { articulo: { persona_actual_id: p1.id, identificador: ident, fecha_ingreso: ingreso } }, # ← incluimos básicos
        headers: headers
    expect(response).to have_http_status(:ok)

    t1 = Transferencia.where(articulo_id: art_id, persona_id: p1.id).order(:id).last
    expect(t1).to be_present
    expect(t1.fecha_fin).to be_nil
    expect(t1.fecha_inicio).to be_within(5.seconds).of(Time.current)  # ✔ update usa Time.current :contentReference[oaicite:4]{index=4}

    # 3) Intentar cambiar portador por update → NO permitido (debe ser via /api/v1/transfers)
    put "/api/v1/articles/#{art_id}",
        params: { articulo: { persona_actual_id: p2.id, identificador: ident, fecha_ingreso: ingreso } },
        headers: headers
    expect(response).to have_http_status(:unprocessable_entity)
    expect(JSON.parse(response.body)["error"].to_s).to match(/ya tiene portador/i)
    end
end
