class Articulo < ApplicationRecord
  belongs_to :modelo
  belongs_to :persona_actual, class_name: "Persona", optional: true
  has_many :transferencias, dependent: :restrict_with_error

  scope :activos, -> { where(activo: true) }

  validates :identificador, :fecha_ingreso, presence: true
  validates :identificador, uniqueness: true
end
