class Marca < ApplicationRecord
  has_many :modelos, dependent: :restrict_with_error
  validates :nombre, presence: true, uniqueness: { case_sensitive: false }
end