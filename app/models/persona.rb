class Persona < ApplicationRecord
  has_many :transferencias, dependent: :restrict_with_error
  has_many :articulos, foreign_key: :persona_actual_id
  validates :nombre, :apellido, presence: true
  scope :activos, -> { where(archivado: false) }
end
