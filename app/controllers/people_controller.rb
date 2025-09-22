class PeopleController < ApplicationController
  def index
    client = ApiClient.new
    q = params[:q].to_s.strip

    api_params = {
      per: 12,
      archivado: false # sólo activos
    }
    api_params[:q]    = q if q.present?
    api_params[:page] = params[:page] if params[:page].present?

    _, body = client.get("/api/v1/people", api_params)

    @people = body.fetch("data", [])
    @meta   = body.fetch("meta", {})

    render layout: !turbo_frame_request?
  end

  def show
    client = ApiClient.new
    _, @persona = client.get("/api/v1/people/#{params[:id]}")

    # Historial completo
    _, arts = client.get("/api/v1/people/#{params[:id]}/articles", { per: 100 })
    @articulos_historial = (arts.is_a?(Hash) ? arts["data"] : arts) || []
  end

  def new
    @prefill = {
      "id"       => params[:id],
      "nombre"   => params[:nombre],
      "apellido" => params[:apellido],
      "identificador" => params[:identificador]
    }.compact
  end

  def create
    client  = ApiClient.new
    attrs   = params.require(:persona).permit(:nombre, :apellido, :identificador).to_h
    _, body = client.post("/api/v1/people", { persona: attrs })
    id = body["id"] || body.dig("data", "id")
    redirect_to person_path(id), notice: "Persona creada."
  rescue ApiClient::UnprocessableEntity, ApiClient::ClientError, ApiClient::ConnectionError => e
    flash.now[:alert] = e.message.presence || "No se pudo crear la persona."
    @prefill = attrs.stringify_keys
    render :new, status: :unprocessable_entity
  end

    def edit
    client = ApiClient.new
    _, body = client.get("/api/v1/people/#{params[:id]}")
    @prefill = {
      "id"       => body["id"],
      "nombre"   => body["nombre"],
      "apellido" => body["apellido"],
      "identificador" => body["identificador"]
    }
    render :new
  rescue ApiClient::ClientError, ApiClient::ConnectionError => e
    redirect_to people_path, alert: e.message
  end

  def update
    client  = ApiClient.new
    attrs   = params.require(:persona).permit(:nombre, :apellido, :identificador).to_h
    client.put("/api/v1/people/#{params[:id]}", { persona: attrs })
    redirect_to person_path(params[:id]), notice: "Persona actualizada."
  rescue ApiClient::UnprocessableEntity, ApiClient::ClientError, ApiClient::ConnectionError => e
    flash.now[:alert] = e.message.presence || "No se pudo actualizar la persona."
    @prefill = attrs.merge("id" => params[:id]).stringify_keys
    render :new, status: :unprocessable_entity
  end

  def destroy
    client = ApiClient.new
    client.delete("/api/v1/people/#{params[:id]}")
    redirect_to people_path, notice: "Persona eliminada/archivada correctamente."
  rescue ApiClient::ClientError => e
    redirect_to people_path, alert: e.message
  end

  def create_modal
    client = ApiClient.new
    payload = {
      persona: {
        nombre:        params[:nombre],
        apellido:      params[:apellido],
        identificador: params[:identificador].presence
      }.compact
    }
    _, body = client.post("/api/v1/people", payload)
    render json: {
      id:    body["id"] || body.dig("data", "id"),
      nombre: params[:nombre],
      apellido: params[:apellido],
      identificador: params[:identificador].presence
    }
  rescue ApiClient::UnprocessableEntity, ApiClient::ClientError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def lookup
    client = ApiClient.new
    _, body = client.get("/api/v1/people", { q: params[:q], per: 8 }.compact)

    list = (body["data"] || [])
    render json: {
      data: list.map { |p|
        {
          id:       p["id"],
          nombre:   p["nombre"],
          apellido: p["apellido"],
          identificador: p["identificador"],
          label: "#{p['identificador']} — #{p['nombre']} #{p['apellido']}"
        }
      }
    }
  end
end
