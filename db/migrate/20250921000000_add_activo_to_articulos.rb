class AddActivoToArticulos < ActiveRecord::Migration[7.1]
  def change
    add_column :articulos, :activo, :boolean, null: false, default: true
    add_index  :articulos, :activo
  end
end
