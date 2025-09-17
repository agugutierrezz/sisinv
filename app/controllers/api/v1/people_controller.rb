class Api::V1::PeopleController < Api::V1::BaseController
  before_action :set_persona, only: [ :show, :update, :destroy ]

  def index
    scope = Persona.all
    scope = scope.where(archivado: ActiveModel::Type::Boolean.new.cast(params[:archivado])) if params.key?(:archivado)
    scope = scope.where("LOWER(nombre)  LIKE ?", "%#{params[:nombre].to_s.downcase}%")   if params[:nombre].present?
    scope = scope.where("LOWER(apellido) LIKE ?", "%#{params[:apellido].to_s.downcase}%") if params[:apellido].present?

    list, page, per = paginate(scope.order(:apellido, :nombre))
    render json: { data: list.as_json(only: [ :id, :nombre, :apellido, :archivado ]),
                   meta: { page:, per:, total: scope.count } }
  end

  def show
    render json: @persona.as_json(only: [ :id, :nombre, :apellido, :archivado ])
  end

  def create
    persona = Persona.new(persona_params)
    persona.save!
    render json: persona.as_json(only: [ :id, :nombre, :apellido, :archivado ]), status: :created
  end

  def update
    @persona.update!(persona_params)
    render json: @persona.as_json(only: [ :id, :nombre, :apellido, :archivado ])
  end

  # “Eliminar” = archivar si tiene historial; si no, borra
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

  private

  def set_persona
    @persona = Persona.find(params[:id])
  end

  def persona_params
    params.require(:persona).permit(:nombre, :apellido)
  end
end
