# Los controladores deben heredar de esta clase para JSON.

class Api::V1::BaseController < ApplicationController
  protect_from_forgery with: :null_session
  skip_before_action :require_authentication, raise: false
  before_action :authenticate_api!

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "Not Found" }, status: :not_found
  end

  rescue_from ActiveRecord::RecordInvalid do |e|
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  rescue_from ActiveRecord::InvalidForeignKey do
    render json: { error: "No se puede eliminar: existen registros asociados" }, status: :unprocessable_entity
  end

  private

  def authenticate_api!
    bearer = request.authorization.to_s[/^Bearer (.+)$/, 1]
    @current_user = User.find_by(api_token: bearer)
    render(json: { error: "Unauthorized" }, status: :unauthorized) and return unless @current_user
  end

  def paginate(scope)
    page = params.fetch(:page, 1).to_i.clamp(1, 1_000_000)
    per  = params.fetch(:per_page, 25).to_i.clamp(1, 100)
    [ scope.offset((page - 1) * per).limit(per), page, per ]
  end
end
