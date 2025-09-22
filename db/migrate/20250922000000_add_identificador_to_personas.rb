class AddIdentificadorToPersonas < ActiveRecord::Migration[7.1]
  def up
    add_column :personas, :identificador, :string
    execute <<~SQL
      UPDATE personas
      SET identificador = COALESCE(
        NULLIF(identificador, ''),
        printf('%08d', id)
      );
    SQL

    change_column_null :personas, :identificador, false
    add_index :personas, :identificador, unique: true
  end

  def down
    remove_index :personas, :identificador
    remove_column :personas, :identificador
  end
end
