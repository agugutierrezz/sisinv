class ModelsController < ApplicationController
  before_action :require_authentication

  def index
    client = ApiClient.new
    params_api = {}
    params_api[:marca_id] = params[:marca_id] if params[:marca_id].present?
    params_api[:q] = params[:q] if params[:q].present?

    _, body = client.get("/api/v1/models", params_api)
    modelos = (body["data"] || body || []).map { |m| { id: m["id"], nombre: m["nombre"] } }
    render json: modelos
  rescue ApiClient::ConnectionError => e
    render json: { error: e.message }, status: :service_unavailable
  end

  def create_modal
    client = ApiClient.new
    payload = { modelo: { marca_id: params[:marca_id], nombre: params[:nombre] } }
    payload[:modelo][:anio] = params[:anio].presence
    _, body = client.post("/api/v1/models", payload)
    render json: { id: body["id"] || body.dig("data", "id"), nombre: params[:nombre], anio: params[:anio].presence }
  rescue ApiClient::UnprocessableEntity, ApiClient::ClientError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def for_brand
    client = ApiClient.new
    params_api = {}
    params_api[:marca_id] = params[:marca_id] if params[:marca_id].present?
    _, body = client.get("/api/v1/models", params_api)
    list = (body["data"] || body || [])
    render json: list.map { |m| { id: m["id"], nombre: m["nombre"], anio: m["anio"] } }
  rescue ApiClient::ConnectionError => e
    render json: { error: e.message }, status: :service_unavailable
  end

  def update
    client = ApiClient.new
    payload = { modelo: {} }
    payload[:modelo][:nombre]   = params[:nombre]   if params.key?(:nombre)
    payload[:modelo][:anio]     = params[:anio].presence if params.key?(:anio)
    payload[:modelo][:marca_id] = params[:marca_id] if params.key?(:marca_id)
    _, body = client.put("/api/v1/models/#{params[:id]}", payload)
    render json: { id: body["id"], nombre: body["nombre"], anio: body["anio"], marca: body["marca"] }
  rescue ApiClient::UnprocessableEntity, ApiClient::ClientError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    client = ApiClient.new
    client.delete("/api/v1/models/#{params[:id]}")
    head :no_content
  rescue ApiClient::ClientError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
