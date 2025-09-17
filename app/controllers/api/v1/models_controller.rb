class Api::V1::ModelsController < Api::V1::BaseController
  before_action :set_modelo, only: [ :show, :update, :destroy ]

  def index
    scope = Modelo.includes(:marca).all
    scope = scope.where(marca_id: params[:marca_id]) if params[:marca_id].present?
    scope = scope.where("LOWER(modelos.nombre) LIKE ?", "%#{params[:q].to_s.downcase}%") if params[:q].present?
    scope = scope.where(anio: params[:anio]) if params[:anio].present?

    list, page, per = paginate(scope.order("marcas.nombre ASC, modelos.nombre ASC, modelos.anio ASC").references(:marca))
    render json: {
      data: list.map { |m|
        { id: m.id, nombre: m.nombre, anio: m.anio, marca: { id: m.marca_id, nombre: m.marca.nombre } }
      },
      meta: { page:, per:, total: scope.count }
    }
  end

  def show
    m = @modelo
    render json: { id: m.id, nombre: m.nombre, anio: m.anio, marca: { id: m.marca_id, nombre: m.marca.nombre } }
  end

  def create
    modelo = Modelo.new(modelo_params)
    modelo.save! # unique index [:marca_id, :nombre, :anio] protege duplicados
    render json: { id: modelo.id }, status: :created
  end

  def update
    @modelo.update!(modelo_params)
    show
  end

  def destroy
    @modelo.destroy! # FK restrict en artículos evitará borrar si tiene artículos
    head :no_content
  end

  private

  def set_modelo
    @modelo = Modelo.find(params[:id])
  end

  def modelo_params
    params.require(:modelo).permit(:nombre, :anio, :marca_id)
  end
end
