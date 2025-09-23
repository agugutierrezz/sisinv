class Api::V1::ModelsController < Api::V1::BaseController
  before_action :set_modelo, only: [ :show, :update, :destroy ]

  def index
    scope = Modelo.includes(:marca).left_joins(:articulos)
    scope = scope.where(marca_id: params[:marca_id]) if params[:marca_id].present?
    scope = scope.where("LOWER(modelos.nombre) LIKE ?", "%#{params[:q].to_s.downcase}%") if params[:q].present?
    scope = scope.where(anio: params[:anio]) if params[:anio].present?

    scope = scope
      .left_joins(:articulos)
      .select("modelos.*, COALESCE(SUM(CASE WHEN articulos.activo THEN 1 ELSE 0 END), 0) AS articulos_count")
      .group("modelos.id")

    total = scope.except(:select, :order).distinct.count("modelos.id")
    list, page, per = paginate(scope.order("marcas.nombre ASC, modelos.nombre ASC, modelos.anio ASC").references(:marca))

    render json: {
      data: list.map { |m|
        {
          id: m.id,
          nombre: m.nombre,
          anio: m.anio,
          marca: { id: m.marca_id, nombre: m.marca.nombre },
          articulos_count: m.read_attribute(:articulos_count).to_i
        }
      },
      meta: { page:, per:, total: total }
    }
  end

  def show
    m = @modelo
    render json: {
      id: m.id,
      nombre: m.nombre,
      anio: m.anio,
      marca: { id: m.marca_id, nombre: m.marca.nombre },
      articulos_count: m.articulos.where(activo: true).count
    }
  end

  def create
    modelo = Modelo.create!(modelo_params)
    render json: { id: modelo.id }, status: :created
  end

  def update
    @modelo.update!(modelo_params)
    show
  end

  def destroy
    if @modelo.destroy
      head :no_content
    else
      render json: { errors: @modelo.errors.full_messages.presence || [ "No se puede eliminar: existen registros asociados" ] },
            status: :unprocessable_entity
    end
  end

  private

  def set_modelo
    @modelo = Modelo.find(params[:id])
  end

  def modelo_params
    params.require(:modelo).permit(:nombre, :anio, :marca_id)
  end
end
