class Transferencia < ApplicationRecord
  self.table_name = "transferencias"

  belongs_to :articulo
  belongs_to :persona

  validates :fecha_inicio, presence: true
end
