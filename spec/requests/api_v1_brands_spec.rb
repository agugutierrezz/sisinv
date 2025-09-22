require "rails_helper"

RSpec.describe "API::V1::Brands", type: :request do
  let!(:user)    { create(:user) }
  let(:headers)  { { "Authorization" => "Bearer #{user.api_token}" } }

  let!(:brand1)  { create(:brand, nombre: "Apple") }
  let!(:brand2)  { create(:brand, nombre: "Acer") }

  let!(:model1)  { create(:model, marca: brand1, nombre: "MacBook", anio: 2024) }
  let!(:model2)  { create(:model, marca: brand2, nombre: "Swift 3", anio: 2022) }

  # un artículo para sumar counts
  let!(:art1)    { create(:article, modelo: model1) }

  def j; JSON.parse(response.body); end

  describe "GET /api/v1/brands" do
    it "lista marcas con counts y meta" do
      get "/api/v1/brands", headers: headers
      expect(response).to have_http_status(:ok)

      body = j
      expect(body["data"]).to be_an(Array)
      row_apple = body["data"].find { |h| h["id"] == brand1.id }
      expect(row_apple).to include(
        "id" => brand1.id,
        "nombre" => "Apple",
        "modelos_count" => 1,
        "articulos_count" => 1
      )
      expect(body["meta"]).to include("page", "per", "total")
    end

    it "filtra por q (por nombre)" do
      get "/api/v1/brands", params: { q: "ap" }, headers: headers
      expect(response).to have_http_status(:ok)
      names = j["data"].map { |h| h["nombre"] }
      expect(names).to include("Apple")
      expect(names).not_to include("Acer") # 'ap' no matchea 'acer'
    end
  end

  describe "GET /api/v1/brands/:id" do
    it "devuelve la marca con counts" do
      get "/api/v1/brands/#{brand1.id}", headers: headers
      expect(response).to have_http_status(:ok)
      body = j
      expect(body).to include(
        "id" => brand1.id,
        "nombre" => "Apple",
        "modelos_count" => 1,
        "articulos_count" => 1
      )
    end
  end

  describe "POST /api/v1/brands" do
    it "crea marca y devuelve counts en 0" do
      post "/api/v1/brands",
           params: { marca: { nombre: "Dell" } },
           headers: headers
      expect(response).to have_http_status(:created)
      body = j
      expect(body).to include("id", "nombre" => "Dell", "modelos_count" => 0, "articulos_count" => 0)
    end
  end

  describe "PUT /api/v1/brands/:id" do
    it "actualiza y responde el show" do
      put "/api/v1/brands/#{brand2.id}",
          params: { marca: { nombre: "Acer Inc." } },
          headers: headers
      expect(response).to have_http_status(:ok)
      expect(j).to include("id" => brand2.id, "nombre" => "Acer Inc.")
    end
  end

  describe "DELETE /api/v1/brands/:id" do
    it "borra si no tiene modelos" do
      b = create(:brand, nombre: "Vacía")
      delete "/api/v1/brands/#{b.id}", headers: headers
      expect(response).to have_http_status(:no_content)
      expect(Marca.where(id: b.id)).not_to exist
    end
  end
end
