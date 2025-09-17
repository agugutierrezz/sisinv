# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_09_17_005003) do
  create_table "articulos", force: :cascade do |t|
    t.string "identificador", null: false
    t.date "fecha_ingreso", null: false
    t.integer "modelo_id", null: false
    t.integer "persona_actual_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["identificador"], name: "index_articulos_on_identificador", unique: true
    t.index ["modelo_id"], name: "index_articulos_on_modelo_id"
    t.index ["persona_actual_id"], name: "index_articulos_on_persona_actual_id"
  end

  create_table "marcas", force: :cascade do |t|
    t.string "nombre", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["nombre"], name: "index_marcas_on_nombre", unique: true
  end

  create_table "modelos", force: :cascade do |t|
    t.string "nombre", null: false
    t.integer "anio"
    t.integer "marca_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["marca_id", "nombre", "anio"], name: "index_modelos_on_marca_nombre_anio", unique: true
    t.index ["marca_id"], name: "index_modelos_on_marca_id"
  end

  create_table "personas", force: :cascade do |t|
    t.string "nombre", null: false
    t.string "apellido", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "transferencias", force: :cascade do |t|
    t.integer "articulo_id", null: false
    t.integer "persona_id", null: false
    t.datetime "fecha_inicio", null: false
    t.datetime "fecha_fin"
    t.text "descripcion"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["articulo_id", "fecha_inicio"], name: "index_transferencias_on_articulo_id_and_fecha_inicio"
    t.index ["articulo_id"], name: "idx_transferencias_one_open_per_articulo", unique: true, where: "fecha_fin IS NULL"
    t.index ["articulo_id"], name: "index_transferencias_on_articulo_id"
    t.index ["persona_id", "fecha_inicio"], name: "index_transferencias_on_persona_id_and_fecha_inicio"
    t.index ["persona_id"], name: "index_transferencias_on_persona_id"
    t.check_constraint "fecha_fin IS NULL OR fecha_fin >= fecha_inicio", name: "chk_transferencias_fin_gte_inicio"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role", default: 0, null: false
    t.string "api_token"
    t.index ["api_token"], name: "index_users_on_api_token", unique: true
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "articulos", "modelos", on_delete: :restrict
  add_foreign_key "articulos", "personas", column: "persona_actual_id", on_delete: :nullify
  add_foreign_key "modelos", "marcas", on_delete: :restrict
  add_foreign_key "sessions", "users"
  add_foreign_key "transferencias", "articulos", on_delete: :restrict
  add_foreign_key "transferencias", "personas", on_delete: :restrict
end
