require "ostruct"

class ArticlesController < ApplicationController
  before_action :require_authentication
  before_action :set_client
  before_action :load_article, only: [ :show, :edit ]
  before_action :load_brands_and_models, only: [ :new, :edit ]
  before_action :load_people, only: [ :new, :edit ]

  def index
    begin
      _, brands = @client.get("/api/v1/brands")
      @marcas = (brands["data"] || brands || []).map { |b| OpenStruct.new(id: b["id"], nombre: b["nombre"]) }

      _, modelos_body = params[:marca_id].present? ?
        @client.get("/api/v1/models", { marca_id: params[:marca_id] }) :
        @client.get("/api/v1/models")
      modelos_json = (modelos_body["data"] || modelos_body || [])
      @modelos = modelos_json.map { |m| OpenStruct.new(id: m["id"], nombre: m["nombre"]) }

      _, articles = @client.get("/api/v1/articles", {
        marca_id: params[:marca_id],
        modelo_id: params[:modelo_id],
        fecha_desde: params[:fecha_desde],
        fecha_hasta: params[:fecha_hasta],
        persona_actual_id: params[:persona_actual_id]
      }.compact)

      list = (articles["data"] || [])
      @articulos = list.map do |a|
        OpenStruct.new(
          id:            a["id"],
          identificador: a["identificador"],
          fecha_ingreso: a["fecha_ingreso"],
          marca:         OpenStruct.new(id: a.dig("marca", "id"),   nombre: a.dig("marca", "nombre")),
          modelo:        OpenStruct.new(id: a.dig("modelo", "id"),  nombre: a.dig("modelo", "nombre"), anio: a.dig("modelo", "anio")),
          persona_actual: (pa = a["persona_actual"]) && OpenStruct.new(id: pa["id"], nombre: pa["nombre"], apellido: pa["apellido"])
        )
      end
    rescue ApiClient::ConnectionError => e
      flash.now[:alert] = e.message
      @marcas = @modelos = @articulos = []
    end
  end

  def show
    load_article
    @transferencias = []

    begin
      _, resp = @client.get("/api/v1/transfers", { articulo_id: params[:id] })
      raw = (resp["data"] || resp || [])

      @transferencias = raw.map do |t|
        persona_hash = t["persona"] || {}
        OpenStruct.new(
          id:         t["id"],
          fecha:      t["fecha"] || t["created_at"] || t["updated_at"],
          comentario: t["comentario"],
          actual:     (t["actual"] == true),
          persona:    OpenStruct.new(
                        id:       persona_hash["id"],
                        nombre:   persona_hash["nombre"],
                        apellido: persona_hash["apellido"]
                      )
        )
      end
      @transferencias.sort_by! { |x| [ x.fecha || "", x.id || 0 ] }.reverse!
    rescue ApiClient::ConnectionError => e
      flash.now[:alert] = e.message
      @transferencias = []
    end

    if @transferencias.empty?
      if @article.persona_actual.present?
        pa = @article.persona_actual
        @transferencias = [
          OpenStruct.new(
            id: nil, fecha: nil, comentario: nil, actual: true,
            persona: OpenStruct.new(id: pa.id, nombre: pa.nombre, apellido: pa.apellido)
          )
        ]
      else
        @transferencias = []
      end
    end
  end

  def new
    @article = OpenStruct.new(identificador: "", fecha_ingreso: nil, marca_id: nil, modelo_id: nil)
  end

  def create
    payload = {
      articulo: {
        identificador: params[:article][:identificador],
        fecha_ingreso: params[:article][:fecha_ingreso],
        marca_id:      presence_i(params[:article][:marca_id]),
        modelo_id:     presence_i(params[:article][:modelo_id])
      }.compact
    }

    if params[:article][:persona_actual_id].present?
      payload[:articulo][:persona_actual_id] = params[:article][:persona_actual_id].to_i
    else
      if params[:article][:persona_nombre].present? && params[:article][:persona_apellido].present?
        payload[:articulo][:persona_nombre]  = params[:article][:persona_nombre]
        payload[:articulo][:persona_apellido]= params[:article][:persona_apellido]
      end
    end

    begin
      _, body = @client.post("/api/v1/articles", payload)
      redirect_to article_path(body["id"]), notice: "Artículo creado."
    rescue ApiClient::UnprocessableEntity => e
      flash.now[:alert] = e.message.presence || "Datos inválidos"
      load_brands_and_models
      @article = OpenStruct.new(payload[:articulo])
      render :new, status: :unprocessable_entity
    rescue ApiClient::ConnectionError => e
      flash.now[:alert] = e.message
      load_brands_and_models
      @article = OpenStruct.new(payload[:articulo])
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @article = Articulo.find(params[:id])
    if @article.respond_to?(:activo) && !@article.activo
      redirect_to article_path(@article), alert: "Artículo archivado: solo lectura." and return
    end
  end

  def update
    payload = {
      articulo: {
        identificador: params[:article][:identificador],
        fecha_ingreso: params[:article][:fecha_ingreso],
        marca_id:      presence_i(params[:article][:marca_id]),
        modelo_id:     presence_i(params[:article][:modelo_id])
      }.compact
    }

    # ¿intentaron setear portador desde la edición?
    new_person_id = presence_i(params.dig(:article, :persona_actual_id))

    if new_person_id
      # Traigo estado FRESCO del artículo para decidir (sin cache)
      _, a = @client.get("/api/v1/articles/#{params[:id]}")

      if a["persona_actual"].present?
        # Ya tiene portador → no permito cambiar desde Editar
        flash[:alert] = "Este artículo ya tiene portador. Para cambiarlo, registrá una transferencia."
      else
        # Estaba sin asignar → permito setear portador inicial
        payload[:articulo][:persona_actual_id] = new_person_id
      end
    end

    begin
      @client.put("/api/v1/articles/#{params[:id]}", payload)
      redirect_to article_path(params[:id]), notice: "Cambios guardados."
    rescue ApiClient::UnprocessableEntity => e
      flash.now[:alert] = e.message.presence || "Datos inválidos"
      load_brands_and_models
      load_article
      render :edit, status: :unprocessable_entity
    rescue ApiClient::ConnectionError => e
      flash.now[:alert] = e.message
      load_brands_and_models
      load_article
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    begin
      @client.delete("/api/v1/articles/#{params[:id]}")
      redirect_to articles_path, notice: "Artículo eliminado."
    rescue ApiClient::UnprocessableEntity => e
      redirect_to article_path(params[:id]), alert: (e.message.presence || "No se puede eliminar este artículo.")
    rescue ApiClient::ConnectionError => e
      redirect_to article_path(params[:id]), alert: e.message
    end
  end

  def lookup
    client = ApiClient.new
    _, resp = client.get("/api/v1/articles", { per: 100 })
    list = (resp["data"] || [])
    q = params[:q].to_s.downcase
    filtered = if q.present?
      list.select { |a|
        [ a["identificador"], a.dig("marca", "nombre"), a.dig("modelo", "nombre") ].compact.join(" ").downcase.include?(q)
      }.first(8)
    else
      list.first(8)
    end
    render json: { data: filtered }
  end


  private

  def set_client
    @client = ApiClient.new
  end

  def presence_i(v)
    v.present? ? v.to_i : nil
  end

  def load_brands_and_models
    _, brands = @client.get("/api/v1/brands")
    @marcas = (brands["data"] || brands || []).map { |b| OpenStruct.new(id: b["id"], nombre: b["nombre"]) }

    effective_brand_id =
      params[:marca_id].presence ||
      (@article&.modelo&.marca_id)   # ← en edit, viene de la asociación

    if effective_brand_id
      _, modelos_body = @client.get("/api/v1/models", { marca_id: effective_brand_id })
    else
      _, modelos_body = @client.get("/api/v1/models")
    end

    modelos_json = (modelos_body["data"] || modelos_body || [])
    @modelos = modelos_json.map { |m| OpenStruct.new(id: m["id"], nombre: m["nombre"], anio: m["anio"]) }
  end

  def load_article
    @article = Rails.cache.fetch("article:#{params[:id]}", expires_in: 10.seconds) do
      _, a = @client.get("/api/v1/articles/#{params[:id]}")
      OpenStruct.new(
        id: a["id"],
        identificador: a["identificador"],
        fecha_ingreso: a["fecha_ingreso"],
        activo: a["activo"],
        marca:  OpenStruct.new(id: a.dig("marca", "id"),  nombre: a.dig("marca", "nombre")),
        modelo: OpenStruct.new(id: a.dig("modelo", "id"), nombre: a.dig("modelo", "nombre"), anio: a.dig("modelo", "anio")),
        persona_actual: (pa = a["persona_actual"]) && OpenStruct.new(id: pa["id"], nombre: pa["nombre"], apellido: pa["apellido"])
      )
    end
  end

  def load_people
    _, resp = @client.get("/api/v1/people")
    list = (resp["data"] || resp || [])
    @personas = list.map { |p| OpenStruct.new(id: p["id"], nombre: p["nombre"], apellido: p["apellido"]) }
  rescue ApiClient::ConnectionError
    @personas = []
  end
end
