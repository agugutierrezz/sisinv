class Api::V1::PeopleController < Api::V1::BaseController
  before_action :set_persona, if: -> { params[:id].present? }

  def index
    archivado = ActiveModel::Type::Boolean.new.cast(params[:archivado])
    scope = Persona.where(archivado: archivado.nil? ? false : archivado)

    if params[:q].present?
      q = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].to_s.downcase)}%"
      scope = scope.where(
        "LOWER(personas.nombre) LIKE :q OR LOWER(personas.apellido) LIKE :q OR LOWER(personas.identificador) LIKE :q",
        q: q
      )
    end

    if params[:nombre].present?
      qn = "%#{ActiveRecord::Base.sanitize_sql_like(params[:nombre].to_s.downcase)}%"
      scope = scope.where("LOWER(personas.nombre) LIKE ?", qn)
    end

    if params[:apellido].present?
      qa = "%#{ActiveRecord::Base.sanitize_sql_like(params[:apellido].to_s.downcase)}%"
      scope = scope.where("LOWER(personas.apellido) LIKE ?", qa)
    end

    total = scope.count
    list, page, per = paginate(scope.order("personas.apellido ASC, personas.nombre ASC"))

    render json: {
      data: list.map { |p|
        { id: p.id, nombre: p.nombre, apellido: p.apellido, identificador: p.identificador, archivado: p.archivado }
      },
      meta: { page:, per:, total: total }
    }
  end

  def show
    render json: @persona.as_json(only: [ :id, :nombre, :apellido, :identificador, :archivado ])
  end

  def create
    persona = Persona.new(persona_params)
    persona.save!
    render json: persona.as_json(only: [ :id, :nombre, :apellido, :identificador, :archivado ]), status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
  end

  def update
    @persona.update!(persona_params)
    render json: @persona.as_json(only: [ :id, :nombre, :apellido, :identificador, :archivado ])
  end

  def destroy
    if @persona.transferencias.exists?
      ActiveRecord::Base.transaction do
        Articulo.where(persona_actual_id: @persona.id).find_each do |art|
          if (abierta = Transferencia.find_by(articulo_id: art.id, fecha_fin: nil))
            abierta.update!(fecha_fin: Time.current, descripcion: [ abierta.descripcion, "(cerrada por archivado de persona)" ].compact.join(" "))
          end
          art.update!(persona_actual_id: nil)
        end
        @persona.update!(archivado: true)
      end
      head :no_content
    else
      @persona.destroy!
      head :no_content
    end
  end

  # GET /api/v1/people/:id/articles
  # Devuelve todos los artículos que la persona tuvo o tiene
  def articles
    ids_por_transfer = Transferencia.where(persona_id: @persona.id).distinct.pluck(:articulo_id)
    ids_actuales     = Articulo.where(persona_actual_id: @persona.id).pluck(:id)
    ids              = (ids_por_transfer | ids_actuales)

    scope = Articulo.includes(modelo: :marca).where(id: ids)
    list, page, per = paginate(scope.order(fecha_ingreso: :desc, id: :asc))

    render json: {
      data: list.map { |a|
        {
          id: a.id,
          identificador: a.identificador,
          fecha_ingreso: a.fecha_ingreso,
          modelo: { id: a.modelo_id, nombre: a.modelo.nombre, anio: a.modelo.anio },
          marca:  { id: a.modelo.marca_id, nombre: a.modelo.marca.nombre },
          actual: (a.activo && a.persona_actual_id == @persona.id), # <<< sólo si activo
          archivado: !a.activo                                       # <<< para mostrar badge
        }
      },
      meta: { page:, per:, total: scope.count }
    }
  end


  private

  def set_persona; @persona = Persona.find(params[:id]); end

  def persona_params
    params.require(:persona).permit(:nombre, :apellido, :identificador)
  end

  # pliega acentos y baja a minúsculas en el parámetro
  def normalize(str)
    I18n.transliterate(str.to_s).downcase
  end

  # pliega acentos en SQL (compatible con SQLite)
  def unaccent_sql(column)
    pairs = [ %w[Á A], %w[á a], %w[É E], %w[é e], %w[Í I], %w[í i],
             %w[Ó O], %w[ó o], %w[Ú U], %w[ú u], %w[Ü U], %w[ü u],
             %w[Ñ N], %w[ñ n] ]
    expr = column
    pairs.each { |from, to| expr = "REPLACE(#{expr}, '#{from}', '#{to}')" }
    "LOWER(#{expr})"
  end
end
