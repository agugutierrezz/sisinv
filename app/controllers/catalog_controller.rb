class CatalogController < ApplicationController
  before_action :require_authentication

  def index
    @tab = params[:tab].in?(%w[models brands]) ? params[:tab] : "brands"
    client = ApiClient.new

    # Filtro de búsqueda (opcional)
    q = params[:q].presence
    @q = q

    _, brands = client.get("/api/v1/brands", { q: q }.compact)
    _, models = client.get("/api/v1/models", { q: q }.compact)

    @brands = (brands["data"] || [])
    @models = (models["data"] || [])
  rescue ApiClient::ConnectionError => e
    flash.now[:alert] = e.message
    @brands = @models = []
  end
end
