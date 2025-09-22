class Api::V1::ArticlesController < Api::V1::BaseController
  before_action :set_articulo, only: [ :show, :update, :destroy ]

  def index
    scope = Articulo.includes(modelo: :marca).activos
    scope = scope.joins(modelo: :marca).where(modelos: { marca_id: params[:marca_id] }) if params[:marca_id].present?
    scope = scope.where(modelo_id: params[:modelo_id])               if params[:modelo_id].present?
    scope = scope.where("fecha_ingreso >= ?", params[:fecha_desde])  if params[:fecha_desde].present?
    scope = scope.where("fecha_ingreso <= ?", params[:fecha_hasta])  if params[:fecha_hasta].present?
    scope = scope.where(persona_actual_id: params[:persona_actual_id]) if params[:persona_actual_id].present?

    if params[:q].present?
      q = "%#{params[:q].to_s.downcase}%"
      scope = scope.joins(modelo: :marca).references(modelo: :marca)
                  .where(
                    "LOWER(articulos.identificador) LIKE :q OR "\
                    "LOWER(modelos.nombre)        LIKE :q OR "\
                    "LOWER(marcas.nombre)         LIKE :q",
                    q: q
                  )
    end

    list, page, per = paginate(scope.order(fecha_ingreso: :desc, id: :asc))
    render json: {
      data: list.map { |a|
        {
          id: a.id,
          identificador: a.identificador,
          fecha_ingreso: a.fecha_ingreso,
          modelo: { id: a.modelo_id, nombre: a.modelo.nombre, anio: a.modelo.anio },
          marca:  { id: a.modelo.marca_id, nombre: a.modelo.marca.nombre },
          persona_actual: a.persona_actual&.slice(:id, :nombre, :apellido)
        }
      },
      meta: { page:, per:, total: scope.count }
    }
  end

  def show
    a = @articulo
    render json: {
      id: a.id,
      identificador: a.identificador,
      fecha_ingreso: a.fecha_ingreso,
      activo: a.activo,
      modelo: { id: a.modelo_id, nombre: a.modelo.nombre, anio: a.modelo.anio },
      marca:  { id: a.modelo.marca_id, nombre: a.modelo.marca.nombre },
      persona_actual: a.persona_actual&.slice(:id, :nombre, :apellido)
    }
  end

  def create
    articulo = build_articulo_from_params!

    Articulo.transaction do
      articulo.save!

      # Si viene con persona_actual, registramos la "asignación inicial"
      if articulo.persona_actual_id.present?
        Transferencia.create!(
          articulo:     articulo,
          persona_id:   articulo.persona_actual_id,
          fecha_inicio: articulo.fecha_ingreso.presence || Time.current,
          descripcion:  "Asignación inicial"
        )
      end
    end

    render json: { id: articulo.id }, status: :created
  end

  def update
    if params.dig(:articulo, :persona_actual_id).present?
      nuevo_id = params[:articulo][:persona_actual_id].to_i

      if @articulo.persona_actual_id.present? && @articulo.persona_actual_id != nuevo_id
        return render json: { error: "Este artículo ya tiene portador. Registrá una transferencia para cambiarlo." },
                      status: :unprocessable_entity
      end

      if @articulo.persona_actual_id.nil?
        Transferencia.transaction do
          Transferencia.create!(
            articulo:     @articulo,
            persona_id:   nuevo_id,
            fecha_inicio: Time.current,
            descripcion:  "Asignación inicial desde edición de artículo"
          )
          @articulo.update!(persona_actual_id: nuevo_id)
        end
      end
    end

    if params.dig(:articulo, :modelo_id).present?
      modelo = Modelo.find(params[:articulo][:modelo_id])
      if params.dig(:articulo, :marca_id).present? &&
        modelo.marca_id != params[:articulo][:marca_id].to_i
        return render json: { error: "El modelo no pertenece a la marca indicada" },
                      status: :unprocessable_entity
      end
      @articulo.update!(modelo:)
    end

    @articulo.update!(identificador: params[:articulo][:identificador]) if params.dig(:articulo, :identificador)
    @articulo.update!(fecha_ingreso: params[:articulo][:fecha_ingreso]) if params.dig(:articulo, :fecha_ingreso)

    show
  end


  def destroy
    if @articulo.transferencias.exists? || @articulo.persona_actual_id.present?
      # cerrar transferencia abierta, si existiera
      if (abierta = Transferencia.find_by(articulo_id: @articulo.id, fecha_fin: nil))
        abierta.update!(fecha_fin: Time.current, descripcion: [ abierta.descripcion, "(cerrada por archivado de artículo)" ].compact.join(" "))
      end
      # desasignar y archivar
      @articulo.update!(activo: false, persona_actual_id: nil)
      head :no_content
    else
      @articulo.destroy!
      head :no_content
    end
  end


  private

  def set_articulo
    @articulo = Articulo.find(params[:id])
  end

  def build_articulo_from_params!
    attrs = articulo_params.to_h.symbolize_keys

    marca = if attrs[:marca_id].present?
      Marca.find(attrs[:marca_id])
    elsif attrs[:marca_nombre].present?
      Marca.find_or_create_by!(nombre: attrs[:marca_nombre])
    end

    modelo = if attrs[:modelo_id].present?
      Modelo.find(attrs[:modelo_id])
    elsif attrs[:modelo_nombre].present?
      raise ActiveRecord::RecordInvalid.new(Articulo.new), "Falta anio para crear el modelo" unless attrs[:modelo_anio].present?
      raise ActiveRecord::RecordInvalid.new(Articulo.new), "Falta marca para crear el modelo" unless marca
      Modelo.find_or_create_by!(marca:, nombre: attrs[:modelo_nombre], anio: attrs[:modelo_anio])
    end
    raise ActiveRecord::RecordInvalid.new(Articulo.new), "modelo es obligatorio" unless modelo

    if attrs[:marca_id].present? && modelo.marca_id != attrs[:marca_id].to_i
      raise ActiveRecord::RecordInvalid.new(Articulo.new), "El modelo no pertenece a la marca indicada"
    end

    persona_actual =
      if attrs[:persona_actual_id].present?
        Persona.find(attrs[:persona_actual_id])
      elsif attrs[:persona_nombre].present? && attrs[:persona_apellido].present?
        Persona.find_or_create_by!(nombre: attrs[:persona_nombre], apellido: attrs[:persona_apellido])
      end

    Articulo.new(
      identificador: attrs[:identificador],
      fecha_ingreso: attrs[:fecha_ingreso],
      modelo: modelo,
      persona_actual: persona_actual
    )
  end

  def articulo_params
    params.require(:articulo).permit(
      :identificador, :fecha_ingreso, :modelo_id, :marca_id, :persona_actual_id,
      :marca_nombre, :modelo_nombre, :modelo_anio, :persona_nombre, :persona_apellido
    )
  end
end
