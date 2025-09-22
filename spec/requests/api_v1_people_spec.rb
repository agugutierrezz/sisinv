require "rails_helper"

RSpec.describe "API::V1::People", type: :request do
  let!(:user)    { create(:user) } # debe tener :api_token
  let(:headers)  { { "Authorization" => "Bearer #{user.api_token}" } }

  describe "GET /api/v1/people" do
    it "requiere token" do
      get "/api/v1/people"
      expect(response).to have_http_status(:unauthorized)
    end

    it "lista personas e incluye identificador en el JSON" do
      create(:person, identificador: "ABC12345", nombre: "Ana", apellido: "García")
      create(:person, identificador: "XYZ99999", nombre: "Juan", apellido: "Pérez")

      get "/api/v1/people", headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"]).to be_an(Array)
      expect(json["data"].first).to include("id", "nombre", "apellido", "identificador", "archivado")
    end

    it "filtra por q (nombre/apellido/identificador)" do
      create(:person, identificador: "ID-00112233", nombre: "María", apellido: "López")
      get "/api/v1/people", params: { q: "00112233" }, headers: headers
      json = JSON.parse(response.body)
      expect(json["data"].map { |p| p["identificador"] }).to include("ID-00112233")
    end
  end

  describe "GET /api/v1/people/:id" do
    it "devuelve la persona con identificador" do
      p = create(:person, identificador: "ID-0001")
      get "/api/v1/people/#{p.id}", headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include(
        "id" => p.id, "nombre" => p.nombre, "apellido" => p.apellido, "identificador" => "ID-0001"
      )
    end
  end

  describe "POST /api/v1/people" do
    it "crea persona con identificador" do
      post "/api/v1/people",
           params: { persona: { nombre: "Luca", apellido: "Mena", identificador: "PERS-123" } },
           headers: headers

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["identificador"]).to eq("PERS-123")
    end

    it "rechaza duplicado de identificador" do
      create(:person, identificador: "DUP-1")
      post "/api/v1/people",
           params: { persona: { nombre: "Otro", apellido: "Mas", identificador: "DUP-1" } },
           headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PUT /api/v1/people/:id" do
    it "actualiza nombre/apellido/identificador" do
      p = create(:person, identificador: "AAA")
      put "/api/v1/people/#{p.id}",
          params: { persona: { nombre: "N", apellido: "A", identificador: "BBB" } },
          headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include("identificador" => "BBB")
    end
  end
end
