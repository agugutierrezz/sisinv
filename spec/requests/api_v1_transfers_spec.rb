require "rails_helper"

RSpec.describe "API::V1::Transfers", type: :request do
  let!(:user)    { create(:user) }
  let(:headers)  { { "Authorization" => "Bearer #{user.api_token}" } }

  let!(:p1) { create(:person) }
  let!(:p2) { create(:person) }
  let!(:art) { create(:article, persona_actual: nil) }

  # Helper para leer el portador_actual/persona_actual sin atarnos a un nombre
  def current_holder_id(record)
    record.reload
    if record.respond_to?(:portador_actual_id)
      record.portador_actual_id
    elsif record.respond_to?(:persona_actual_id)
      record.persona_actual_id
    else
      nil
    end
  end

  it "crea la PRIMERA transferencia (fecha_inicio requerida), deja abierta y actualiza portador actual" do
    post "/api/v1/transfers",
         params: {
           transferencia: {
             articulo_id:  art.id,
             persona_id:   p1.id,
             fecha_inicio: "2025-09-01",
             descripcion:  "Asignación inicial"
           }
         },
         headers: headers

    expect(response).to have_http_status(:created)

    t = Transferencia.where(articulo_id: art.id, persona_id: p1.id).order(:id).last
    expect(t).to be_present
    expect(t.fecha_inicio.to_date).to eq(Date.new(2025, 9, 1))
    expect(t.fecha_fin).to be_nil
    expect(current_holder_id(art)).to eq(p1.id)
  end

  it "al crear una NUEVA transferencia, cierra la anterior con fecha_fin = fecha_inicio nueva y actualiza portador actual" do
    # Primera (abierta)
    post "/api/v1/transfers",
         params: { transferencia: { articulo_id: art.id, persona_id: p1.id, fecha_inicio: "2025-09-01" } },
         headers: headers
    t1 = Transferencia.where(articulo_id: art.id, persona_id: p1.id).order(:id).last
    expect(t1).to be_present
    expect(t1.fecha_fin).to be_nil
    expect(current_holder_id(art)).to eq(p1.id)

    # Segunda (cierra la anterior y pasa a p2)
    post "/api/v1/transfers",
         params: { transferencia: { articulo_id: art.id, persona_id: p2.id, fecha_inicio: "2025-09-02", descripcion: "Cambio" } },
         headers: headers
    expect(response).to have_http_status(:created)

    t1.reload
    t2 = Transferencia.where(articulo_id: art.id, persona_id: p2.id).order(:id).last
    expect(t2).to be_present
    expect(t1.fecha_fin.to_date).to eq(Date.new(2025, 9, 2))
    expect(t2.fecha_inicio.to_date).to eq(Date.new(2025, 9, 2))
    expect(t2.fecha_fin).to be_nil
    expect(current_holder_id(art)).to eq(p2.id)
  end

  it "si no envío fecha_inicio, la API completa con Time.current y crea la transferencia" do
    post "/api/v1/transfers",
         params: { transferencia: { articulo_id: art.id, persona_id: p1.id, descripcion: "Sin fecha" } },
         headers: headers
    expect(response).to have_http_status(:created)

    t = Transferencia.where(articulo_id: art.id, persona_id: p1.id).order(:id).last
    expect(t).to be_present
    expect(t.fecha_inicio).to be_within(5.seconds).of(Time.current)
  end
end
