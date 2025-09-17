class Api::V1::BrandsController < Api::V1::BaseController
  before_action :set_marca, only: [ :show, :update, :destroy ]

  def index
    scope = Marca.all
    scope = scope.where("LOWER(nombre) LIKE ?", "%#{params[:q].to_s.downcase}%") if params[:q].present?

    list, page, per = paginate(scope.order(:nombre))
    render json: {
      data: list.as_json(only: [ :id, :nombre ]),
      meta: { page:, per:, total: scope.count }
    }
  end

  def show
    render json: @marca.as_json(only: [ :id, :nombre ])
  end

  def create
    marca = Marca.new(marca_params)
    marca.save!
    render json: marca.as_json(only: [ :id, :nombre ]), status: :created
  end

  def update
    @marca.update!(marca_params)
    render json: @marca.as_json(only: [ :id, :nombre ])
  end

  def destroy
    @marca.destroy! # FK restrict en modelos evitará borrar si tiene modelos
    head :no_content
  end

  private

  def set_marca
    @marca = Marca.find(params[:id])
  end

  def marca_params
    params.require(:marca).permit(:nombre)
  end
end
