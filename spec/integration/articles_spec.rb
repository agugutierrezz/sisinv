require "swagger_helper"

RSpec.describe "api/v1/articles", type: :request do
  include_context "api_auth"

  # Datos base para este archivo
  let!(:marca)   { Marca.create!(nombre: "Apple") }
  let!(:modelo)  { Modelo.create!(marca:, nombre: "MacBook Air", anio: 2024) }
  let!(:persona) { Persona.create!(nombre: "Ana", apellido: "García") }

  # Uno sin portador y otro con portador, para distintos casos
  let!(:articulo) do
    Articulo.create!(identificador: "ART-001", fecha_ingreso: Date.today, modelo:, persona_actual: nil)
  end
  let!(:art_con_portador) do
    Articulo.create!(identificador: "ART-PORTA", fecha_ingreso: Date.today, modelo:, persona_actual: persona)
  end

  path "/api/v1/articles" do
    parameter name: "Authorization", in: :header, schema: { type: :string }, required: true
    let(:Authorization) { "Bearer #{api_user.api_token}" }

    get "Lista artículos (activos) con filtros" do
      tags "Articles"
      produces "application/json"

      response "200", "ok" do
        run_test!
      end
    end

    post "Crea artículo (permite crear/usar marca y modelo, y asignar persona inicial)" do
      tags "Articles"
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        properties: {
          articulo: {
            type: :object,
            properties: {
              identificador:     { type: :string },
              fecha_ingreso:     { type: :string, format: :date },
              modelo_id:         { type: :integer, nullable: true },
              marca_id:          { type: :integer, nullable: true },
              marca_nombre:      { type: :string,  nullable: true },
              modelo_nombre:     { type: :string,  nullable: true },
              modelo_anio:       { type: :integer, nullable: true },
              persona_actual_id: { type: :integer, nullable: true },
              persona_nombre:    { type: :string,  nullable: true },
              persona_apellido:  { type: :string,  nullable: true }
            },
            required: %w[identificador fecha_ingreso]
          }
        },
        required: [ "articulo" ]
      }

      response "201", "created" do
        let(:body) do
          {
            articulo: {
              identificador: "ART-NEW",
              fecha_ingreso: Date.today.to_s,
              modelo_id: modelo.id,
              persona_actual_id: persona.id
            }
          }
        end
        run_test!
      end

      response "422", "datos inválidos (modelo/ marca inconsistentes o faltantes)" do
        let!(:otra_marca) { Marca.create!(nombre: "HP") }
        let(:body) do
          {
            articulo: {
              identificador: "ART-BAD",
              fecha_ingreso: Date.today.to_s,
              modelo_id: modelo.id,
              marca_id:  otra_marca.id # <- NO coincide con el modelo
            }
          }
        end
        run_test!
      end
    end
  end

  path "/api/v1/articles/{id}" do
    parameter name: "Authorization", in: :header, schema: { type: :string }, required: true
    let(:Authorization) { "Bearer #{api_user.api_token}" }
    parameter name: :id, in: :path, required: true, schema: { type: :integer }

    get "Muestra un artículo" do
      tags "Articles"
      produces "application/json"

      response "200", "ok" do
        let(:id) { articulo.id }
        run_test!
      end

      response "404", "no encontrado" do
        let(:id) { 9_999 }
        run_test!
      end
    end

    put "Actualiza un artículo (…)" do
      tags "Articles"
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        properties: { articulo: { type: :object } },
        required: [ "articulo" ]
      }

      response "200", "ok (devuelve show)" do
        let(:id)   { articulo.id }
        let(:body) { { articulo: { identificador: "ART-EDIT" } } }
        run_test!
      end

      response "422", "el artículo ya tiene portador (usar /transfers para cambiarlo)" do
        let(:id)   { art_con_portador.id }
        let(:body) { { articulo: { persona_actual_id: persona.id } } }
        run_test!
      end

      response "404", "no encontrado" do
        let(:id)   { 9_999 }
        let(:body) { { articulo: { identificador: "X" } } }
        run_test!
      end
    end

    delete "Elimina/archiva un artículo (…)" do
      tags "Articles"
      produces "application/json"

      response "204", "no content" do
        let(:id) { articulo.id }
        run_test!
      end

      response "404", "no encontrado" do
        let(:id) { 9_999 }
        run_test!
      end
    end
  end
end
