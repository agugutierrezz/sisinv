class AddArchivadoToPersonas < ActiveRecord::Migration[8.0]
  def change
    add_column :personas, :archivado, :boolean, default: false, null: false
    add_index  :personas, :archivado
  end
end
