class Modelo < ApplicationRecord
  belongs_to :marca
  has_many :articulos, dependent: :nullify
  validates :nombre, presence: true
  before_destroy :ensure_no_active_articles

  def ensure_no_active_articles
    if articulos.where(activo: true).exists?
      errors.add(:base, "No se puede eliminar: tiene artículos activos")
      throw :abort
    end
  end
end
