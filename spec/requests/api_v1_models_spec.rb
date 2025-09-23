require "rails_helper"

RSpec.describe "API::V1::Models", type: :request do
  let!(:user)    { create(:user) }
  let(:headers)  { { "Authorization" => "Bearer #{user.api_token}" } }

  let!(:brand_acer)  { create(:brand, nombre: "Acer") }
  let!(:brand_apple) { create(:brand, nombre: "Apple") }

  let!(:m_swift) { create(:model, marca: brand_acer,  nombre: "Swift 3", anio: 2022) }
  let!(:m_air)   { create(:model, marca: brand_apple, nombre: "MacBook Air", anio: 2024) }

  let!(:art)     { create(:article, modelo: m_swift) } # suma count

  def j; JSON.parse(response.body); end

  describe "GET /api/v1/models" do
    it "lista con counts y meta" do
      get "/api/v1/models", headers: headers
      expect(response).to have_http_status(:ok)
      body = j
      expect(body["data"]).to be_an(Array)
      swift = body["data"].find { |h| h["id"] == m_swift.id }
      expect(swift).to include(
        "id" => m_swift.id,
        "nombre" => "Swift 3",
        "anio" => 2022,
        "articulos_count" => 1,
        "marca" => { "id" => brand_acer.id, "nombre" => "Acer" }
      )
      expect(body["meta"]).to include("page", "per", "total")
    end

    it "filtra por marca_id" do
      get "/api/v1/models", params: { marca_id: brand_acer.id }, headers: headers
      names = j["data"].map { |h| h["nombre"] }
      expect(names).to include("Swift 3")
      expect(names).not_to include("MacBook Air")
    end

    it "filtra por q (nombre) y por anio" do
      get "/api/v1/models", params: { q: "air" }, headers: headers
      expect(j["data"].map { |h| h["nombre"] }).to eq([ "MacBook Air" ])

      get "/api/v1/models", params: { anio: 2022 }, headers: headers
      expect(j["data"].map { |h| h["nombre"] }).to include("Swift 3")
      expect(j["data"].map { |h| h["nombre"] }).not_to include("MacBook Air")
    end
  end

  describe "GET /api/v1/models/:id" do
    it "devuelve datos + marca + articulos_count" do
      get "/api/v1/models/#{m_air.id}", headers: headers
      expect(response).to have_http_status(:ok)
      expect(j).to include(
        "id" => m_air.id,
        "nombre" => "MacBook Air",
        "anio" => 2024,
        "marca" => { "id" => brand_apple.id, "nombre" => "Apple" },
        "articulos_count" => 0
      )
    end
  end

  describe "POST /api/v1/models" do
    it "crea el modelo" do
      post "/api/v1/models",
           params: { modelo: { nombre: "Swift X", anio: 2023, marca_id: brand_acer.id } },
           headers: headers
      expect(response).to have_http_status(:created)
      expect(j).to include("id")
    end
  end

  describe "PUT /api/v1/models/:id" do
    it "actualiza y responde el show" do
      put "/api/v1/models/#{m_swift.id}",
          params: { modelo: { nombre: "Swift 3 (RZ)", anio: 2022, marca_id: brand_acer.id } },
          headers: headers
      expect(response).to have_http_status(:ok)
      expect(j).to include(
        "id" => m_swift.id,
        "nombre" => "Swift 3 (RZ)",
        "anio" => 2022
      )
    end
  end

  describe "DELETE /api/v1/models/:id" do
    it "borra si no tiene artículos" do
      m = create(:model, marca: brand_acer, nombre: "Vacío", anio: 2021)
      delete "/api/v1/models/#{m.id}", headers: headers
      expect(response).to have_http_status(:no_content)
      expect(Modelo.where(id: m.id)).not_to exist
    end
  end
end
