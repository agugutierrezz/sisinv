class CreateInitialSchema < ActiveRecord::Migration[8.0]
  def up
    # PERSONAS
    create_table :personas do |t|
      t.string :nombre,  null: false
      t.string :apellido, null: false
      t.timestamps # created_at/updated_at
    end

    # MARCAS
    create_table :marcas do |t|
      t.string :nombre, null: false
      t.timestamps # created_at/updated_at
    end
    add_index :marcas, :nombre, unique: true

    # MODELOS
    create_table :modelos do |t|
      t.string  :nombre, null: false
      t.integer :anio
      t.references :marca, null: false, foreign_key: { on_delete: :restrict }
      t.timestamps # created_at/updated_at
    end
    add_index :modelos, [ :marca_id, :nombre, :anio ], unique: true, name: "index_modelos_on_marca_nombre_anio"

    # ARTICULOS
    create_table :articulos do |t|
      t.string  :identificador,  null: false  # código/serial único de la unidad física
      t.date    :fecha_ingreso,  null: false
      t.references :modelo,       null: false, foreign_key: { on_delete: :restrict }
      t.references :persona_actual, null: true, foreign_key: { to_table: :personas, on_delete: :nullify }
      t.timestamps # created_at/updated_at
    end
    add_index :articulos, :identificador, unique: true

    # TRANSFERENCIAS (histórico M:N: articulo <-> persona, con intervalo)
    create_table :transferencias do |t|
      t.references :articulo, null: false, foreign_key: { on_delete: :restrict }
      t.references :persona,  null: false, foreign_key: { on_delete: :restrict }
      t.datetime :fecha_inicio, null: false
      t.datetime :fecha_fin,    null: true
      t.text     :descripcion
      t.timestamps # created_at/updated_at
    end
    add_index :transferencias, [ :articulo_id, :fecha_inicio ]
    add_index :transferencias, [ :persona_id,  :fecha_inicio ]

    # Check: fecha_fin >= fecha_inicio (si hay fecha_fin)
    add_check_constraint :transferencias,
                         "fecha_fin IS NULL OR fecha_fin >= fecha_inicio",
                         name: "chk_transferencias_fin_gte_inicio"

    # ÚNICA transferencia abierta (fecha_fin IS NULL) por artículo
    if ActiveRecord::Base.connection.adapter_name.downcase.include?('sqlite')
      execute <<~SQL
        CREATE UNIQUE INDEX idx_transferencias_one_open_per_articulo
        ON transferencias(articulo_id)
        WHERE fecha_fin IS NULL;
      SQL
    else
      add_index :transferencias, :articulo_id,
                unique: true,
                where: "fecha_fin IS NULL",
                name: "idx_transferencias_one_open_per_articulo"
    end
  end

  # Limpia en orden inverso (borra índice parcial/check y luego tablas).
  def down
    if ActiveRecord::Base.connection.adapter_name.downcase.include?('sqlite')
      execute "DROP INDEX IF EXISTS idx_transferencias_one_open_per_articulo"
    else
      remove_index :transferencias, name: "idx_transferencias_one_open_per_articulo"
    end

    remove_check_constraint :transferencias, name: "chk_transferencias_fin_gte_inicio"

    drop_table :transferencias
    drop_table :articulos
    drop_table :modelos
    drop_table :marcas
    drop_table :personas
  end
end
