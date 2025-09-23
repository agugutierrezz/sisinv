class TransfersController < ApplicationController
  def index; end

  def new
    @prefill = {}

    if params[:article_id].present?
      client = ApiClient.new
      _, a = client.get("/api/v1/articles/#{params[:article_id]}")

      if a.is_a?(Hash) && a["activo"] == false
        redirect_to article_path(a["id"]),
                    alert: "Este artículo está archivado; no puede transferirse." and return
      end

      @prefill[:articulo_id]  = a["id"]
      @prefill[:ident_text]   = "#{a['identificador']} — #{a.dig('marca', 'nombre')} #{a.dig('modelo', 'nombre')}"
      @prefill[:desde_id]     = a.dig("persona_actual", "id")
      @prefill[:desde_text]   = a["persona_actual"].present? ?
                                  "#{a.dig('persona_actual', 'nombre')} #{a.dig('persona_actual', 'apellido')}" :
                                  "Sin asignar"
    end
  end


  def create
    client = ApiClient.new

    payload = {
      transferencia: {
        articulo_id:  params.dig(:transfer, :articulo_id).to_i,
        persona_id:   params.dig(:transfer, :persona_id).to_i,
        fecha_inicio: params.dig(:transfer, :fecha_inicio),
        descripcion:  params.dig(:transfer, :descripcion)
      }.compact
    }

    _, body = client.post("/api/v1/transfers", payload)
    redirect_to article_path(payload[:transferencia][:articulo_id]), notice: "Transferencia registrada."
  rescue ApiClient::UnprocessableEntity, ApiClient::ClientError => e
    flash.now[:alert] = e.message.presence || "No se pudo registrar la transferencia."
    # Re-hidrato datos para volver a renderizar el form
    new
    render :new, status: :unprocessable_entity
  rescue ApiClient::ConnectionError => e
    flash.now[:alert] = e.message
    new
    render :new, status: :service_unavailable
  end
end
