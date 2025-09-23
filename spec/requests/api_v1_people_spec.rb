require "rails_helper"

RSpec.describe "API::V1::People", type: :request do
  include_context "api_auth"
  it "GET /api/v1/people filtra por q (nombre/apellido/identificador)" do
    Persona.create!(nombre: "Ana", apellido: "García", identificador: "ID-00112233")
    get "/api/v1/people", params: { q: "00112233" }, headers: auth_headers
    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json["data"].map { |p| p["identificador"] }).to include("ID-00112233")
  end
end
