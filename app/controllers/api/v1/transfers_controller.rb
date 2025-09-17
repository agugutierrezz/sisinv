class Api::V1::TransfersController < Api::V1::BaseController
  before_action :set_transferencia, only: [ :show, :update, :destroy ]

  def index
    scope = Transferencia.includes(:articulo, :persona).all
    scope = scope.where(articulo_id: params[:articulo_id]) if params[:articulo_id].present?
    scope = scope.where(persona_id:  params[:persona_id])  if params[:persona_id].present?

    list, page, per = paginate(scope.order(fecha_inicio: :desc, id: :desc))
    render json: {
      data: list.map { |t|
        t.slice(:id, :articulo_id, :persona_id, :fecha_inicio, :fecha_fin, :descripcion)
      },
      meta: { page:, per:, total: scope.count }
    }
  end

  def show
    render json: @transferencia.slice(:id, :articulo_id, :persona_id, :fecha_inicio, :fecha_fin, :descripcion)
  end

  def create
    articulo = Articulo.find(transfer_params[:articulo_id])
    persona  = Persona.find(transfer_params[:persona_id])
    inicio   = transfer_params[:fecha_inicio].presence || Time.current

    Transferencia.transaction do
      if (abierta = Transferencia.find_by(articulo_id: articulo.id, fecha_fin: nil))
        abierta.update!(fecha_fin: inicio)
      end
      nueva = Transferencia.create!(
        articulo: articulo,
        persona: persona,
        fecha_inicio: inicio,
        descripcion: transfer_params[:descripcion]
      )
      articulo.update!(persona_actual: persona)
      render json: nueva.slice(:id, :articulo_id, :persona_id, :fecha_inicio, :fecha_fin, :descripcion), status: :created
    end
  end

  def update
    @transferencia.update!(transfer_params.slice(:descripcion, :fecha_fin))
    show
  end

  def destroy
    render json: { error: "No se permite eliminar transferencias (trazabilidad)" }, status: :unprocessable_entity
  end

  private

  def set_transferencia
    @transferencia = Transferencia.find(params[:id])
  end

  def transfer_params
    params.require(:transferencia).permit(:articulo_id, :persona_id, :fecha_inicio, :fecha_fin, :descripcion)
  end
end
