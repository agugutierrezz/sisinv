require "rails_helper"

RSpec.describe "API::V1::People#articles", type: :request do
  let!(:user)    { create(:user) }
  let(:headers)  { { "Authorization" => "Bearer #{user.api_token}" } }

  let!(:marca)   { create(:brand) }
  let!(:modelo)  { create(:model, marca:) }
  let!(:p1)      { create(:person) }
  let!(:p2)      { create(:person) }

  it "devuelve los artículos que la persona tuvo o tiene, con flags actual/archivado y meta de paginación" do
    # art1: actualmente en p1, activo
    art1 = create(:article, persona_actual: p1, modelo:)
    create(:transferencia, articulo: art1, persona: p1, fecha_inicio: Date.today, fecha_fin: nil)

    # art2: lo tuvo p1 en el pasado (transferido a p2), y está archivado
    art2 = create(:article, persona_actual: p2, modelo:, )
    create(:transferencia, articulo: art2, persona: p1, fecha_inicio: Date.today - 7, fecha_fin: Date.today - 1)
    create(:transferencia, articulo: art2, persona: p2, fecha_inicio: Date.today - 1, fecha_fin: nil)
    art2.update!(activo: false)

    get "/api/v1/people/#{p1.id}/articles", params: { per: 100 }, headers: headers
    expect(response).to have_http_status(:ok)

    body = JSON.parse(response.body)
    expect(body["data"]).to be_an(Array)
    ids = body["data"].map { |h| h["id"] }

    expect(ids).to include(art1.id, art2.id)

    row1 = body["data"].find { |h| h["id"] == art1.id }
    expect(row1["actual"]).to eq(true)     # p1 es portador actual de art1 y art1 activo
    expect(row1["archivado"]).to eq(false)

    row2 = body["data"].find { |h| h["id"] == art2.id }
    expect(row2["actual"]).to eq(false)    # ya no lo tiene p1
    expect(row2["archivado"]).to eq(true)  # art2 inactivo

    expect(body["meta"]).to include("page", "per", "total")
  end
end
