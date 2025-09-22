require "rails_helper"

RSpec.describe "API::V1::People#index archivado/filtros", type: :request do
  include_context "api_auth"

  it "filtra por nombre y apellido cuando se pasan por separado" do
    p1 = Persona.create!(nombre: "Ana",   apellido: "García", archivado: false)
    _p2 = Persona.create!(nombre: "Bruno", apellido: "García", archivado: false)

    get "/api/v1/people", params: { nombre: "Ana", apellido: "García" }, headers: auth_headers
    expect(response).to have_http_status(:ok)

    list = JSON.parse(response.body)["data"]
    expect(list.map { |h| h["id"] }).to eq([ p1.id ])
  end
end
