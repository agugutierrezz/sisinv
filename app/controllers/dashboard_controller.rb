class DashboardController < ApplicationController
  def index
    @articles_count       = Articulo.where(activo: true).count
    @articles_available   = Articulo.where(persona_actual: nil).count
    @people_count         = Persona.count
    @transfers_count      = Transferencia.count
  end
end
