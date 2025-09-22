class BrandsController < ApplicationController
  before_action :require_authentication

  def index
    @tab = %w[brands models].include?(params[:tab]) ? params[:tab] : "brands"

    client = ApiClient.new

    _, b = client.get("/api/v1/brands", { per: 1000 })
    @brands = (b["data"] || []).map { |x|
      { "id"=>x["id"], "nombre"=>x["nombre"],
        "modelos_count"=>x["modelos_count"].to_i, "articulos_count"=>x["articulos_count"].to_i }
    }

    _, m = client.get("/api/v1/models", { per: 1000 })
    @models = (m["data"] || []).map { |x|
      { "id"=>x["id"], "nombre"=>x["nombre"], "anio"=>x["anio"],
        "marca"=>x["marca"], "articulos_count"=>x["articulos_count"].to_i }
    }
  rescue ApiClient::ConnectionError => e
    flash.now[:alert] = "No se pudo conectar con la API: #{e.message}"
    @brands = []; @models = []
  end

  def list
    client = ApiClient.new
    params_api = {}
    params_api[:q] = params[:q] if params[:q].present?
    _, body = client.get("/api/v1/brands", params_api)
    render json: (body["data"] || body || []).map { |b| { id: b["id"], nombre: b["nombre"] } }
  rescue ApiClient::ConnectionError => e
    render json: { error: e.message }, status: :service_unavailable
  end

  def create_modal
    client = ApiClient.new
    _, body = client.post("/api/v1/brands", { marca: { nombre: params[:nombre] } })
    render json: { id: body["id"] || body.dig("data", "id"), nombre: params[:nombre] }
  rescue ApiClient::UnprocessableEntity, ApiClient::ClientError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update
    client = ApiClient.new
    _, body = client.put("/api/v1/brands/#{params[:id]}", { marca: { nombre: params[:nombre] } })
    render json: { id: body["id"], nombre: body["nombre"] }
  rescue ApiClient::UnprocessableEntity, ApiClient::ClientError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    client = ApiClient.new
    client.delete("/api/v1/brands/#{params[:id]}")
    head :no_content
  rescue ApiClient::ClientError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
