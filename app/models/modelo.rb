class Modelo < ApplicationRecord
  belongs_to :marca
  has_many :articulos, dependent: :restrict_with_error
  validates :nombre, presence: true
end
