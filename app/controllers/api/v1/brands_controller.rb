class Api::V1::BrandsController < Api::V1::BaseController
  before_action :set_marca, only: [ :show, :update, :destroy ]

  def index
    scope = Marca.left_joins(modelos: :articulos)
    scope = scope.where("LOWER(marcas.nombre) LIKE ?", "%#{params[:q].to_s.downcase}%") if params[:q].present?

    scope = scope
      .left_joins(modelos: :articulos)
      .select(
        "marcas.*," \
        "COUNT(DISTINCT modelos.id) AS modelos_count," \
        "COALESCE(SUM(CASE WHEN articulos.activo THEN 1 ELSE 0 END), 0) AS articulos_count"
      )
      .group("marcas.id")

    total = scope.except(:select, :order).distinct.count("marcas.id")
    list, page, per = paginate(scope.order("marcas.nombre ASC"))

    render json: {
      data: list.map { |m|
        {
          id: m.id,
          nombre: m.nombre,
          modelos_count:   m.read_attribute(:modelos_count).to_i,
          articulos_count: m.read_attribute(:articulos_count).to_i
        }
      },
      meta: { page:, per:, total: total }
    }
  end

  def show
    modelos_count   = @marca.modelos.count
    articulos_count = Articulo.joins(:modelo).where(modelos: { marca_id: @marca.id }).count
    render json: { id: @marca.id, nombre: @marca.nombre, modelos_count:, articulos_count: }
  end

  def create
    marca = Marca.create!(marca_params)
    render json: { id: marca.id, nombre: marca.nombre, modelos_count: 0, articulos_count: 0 }, status: :created
  end

  def update
    @marca.update!(marca_params)
    show
  end

  def destroy
    if @marca.destroy
      head :no_content
    else
      render json: { errors: @marca.errors.full_messages.presence || [ "No se puede eliminar: existen modelos asociados" ] },
            status: :unprocessable_entity
    end
  end

  private
  def set_marca; @marca = Marca.find(params[:id]); end
  def marca_params; params.require(:marca).permit(:nombre); end
end
