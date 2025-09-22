require "rails_helper"

RSpec.describe "API::V1::People#index archivado/filtros", type: :request do
  let!(:user)    { create(:user) }
  let(:headers)  { { "Authorization" => "Bearer #{user.api_token}" } }

  it "por defecto devuelve sólo activos; con archivado=true devuelve archivados" do
    activo    = create(:person, nombre: "Ana",  apellido: "Vivas",  archivado: false)
    archivado = create(:person, nombre: "Ari",  apellido: "Viejo",  archivado: true)

    get "/api/v1/people", headers: headers
    list = JSON.parse(response.body)["data"]
    ids  = list.map { |h| h["id"] }
    expect(ids).to include(activo.id)
    expect(ids).not_to include(archivado.id)

    get "/api/v1/people", params: { archivado: true }, headers: headers
    list = JSON.parse(response.body)["data"]
    ids  = list.map { |h| h["id"] }
    expect(ids).to include(archivado.id)
    expect(ids).not_to include(activo.id)
  end

  it "filtra por nombre y apellido cuando se pasan por separado" do
    p1 = create(:person, nombre: "María", apellido: "López")
    _p2 = create(:person, nombre: "Juan",  apellido: "Perez")

    get "/api/v1/people", params: { nombre: "mar", apellido: "lop" }, headers: headers
    list = JSON.parse(response.body)["data"]
    expect(list.map { |h| h["id"] }).to eq([ p1.id ])
  end
end
