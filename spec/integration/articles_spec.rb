require 'swagger_helper'

RSpec.describe 'api/v1/articles', type: :request do
  include_context "api_auth"
  path '/api/v1/articles' do
    parameter name: "Authorization", in: :header, schema: { type: :string }, required: true,
            description: "Bearer <api_token>"
    let(:Authorization) { "Bearer #{api_user.api_token}" }

    get 'Lista artículos (activos) con filtros' do
      tags 'Articles'
      produces 'application/json'
      parameter name: :Authorization,      in: :header, required: true,  schema: { type: :string }
      parameter name: :per,                in: :query,  required: false, schema: { type: :integer, example: 12 }
      parameter name: :page,               in: :query,  required: false, schema: { type: :integer, example: 1 }
      parameter name: :marca_id,           in: :query,  required: false, schema: { type: :integer }
      parameter name: :modelo_id,          in: :query,  required: false, schema: { type: :integer }
      parameter name: :fecha_desde,        in: :query,  required: false, schema: { type: :string, format: :date }
      parameter name: :fecha_hasta,        in: :query,  required: false, schema: { type: :string, format: :date }
      parameter name: :persona_actual_id,  in: :query,  required: false, schema: { type: :integer }
      parameter name: :q,                  in: :query,  required: false, schema: { type: :string,  example: 'macbook' }

      response '200', 'ok' do
        let(:Authorization) { 'Bearer <token>' }
        run_test!
      end
    end

    post 'Crea artículo (permite crear/usar marca y modelo, y asignar persona inicial)' do
      tags 'Articles'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :Authorization, in: :header, required: true, schema: { type: :string }
      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        properties: {
          articulo: {
            type: :object,
            properties: {
              identificador:     { type: :string, example: 'ART-0001' },
              fecha_ingreso:     { type: :string, format: :date, example: '2025-09-01' },

              # Opción 1: referenciar modelo/marca por IDs
              modelo_id:         { type: :integer, nullable: true },
              marca_id:          { type: :integer, nullable: true },

              # Opción 2: crear/usar por nombre (requiere modelo_anio y marca existente o por nombre)
              marca_nombre:      { type: :string,  nullable: true, example: 'Apple' },
              modelo_nombre:     { type: :string,  nullable: true, example: 'MacBook Air' },
              modelo_anio:       { type: :integer, nullable: true, example: 2024 },

              # Asignación inicial de persona (una de las dos variantes)
              persona_actual_id: { type: :integer, nullable: true },
              persona_nombre:    { type: :string,  nullable: true },
              persona_apellido:  { type: :string,  nullable: true }
            },
            required: %w[identificador fecha_ingreso]
          }
        },
        required: [ 'articulo' ]
      }

      response '201', 'created' do
        let(:Authorization) { 'Bearer <token>' }
        let(:body) do
          {
            articulo: {
              identificador: 'ART-0001',
              fecha_ingreso: '2025-09-01',
              modelo_id: 1,      # o bien (marca_nombre, modelo_nombre, modelo_anio)
              persona_actual_id: 2
            }
          }
        end
        run_test!
      end

      response '422', 'datos inválidos (modelo/ marca inconsistentes o faltantes)' do
        let(:Authorization) { 'Bearer <token>' }
        let(:body) do
          {
            articulo: {
              identificador: 'ART-0002',
              fecha_ingreso: '2025-09-01',
              modelo_id: 1,
              marca_id:  999 # <- no coincide con el modelo
            }
          }
        end
        run_test!
      end
    end
  end

  path '/api/v1/articles/{id}' do
    parameter name: "Authorization", in: :header, schema: { type: :string }, required: true,
            description: "Bearer <api_token>"
    let(:Authorization) { "Bearer #{api_user.api_token}" }
    parameter name: :id, in: :path, required: true, schema: { type: :integer }
    parameter name: :Authorization, in: :header, required: true, schema: { type: :string }

    get 'Muestra un artículo' do
      tags 'Articles'
      produces 'application/json'

      response '200', 'ok' do
        let(:Authorization) { 'Bearer <token>' }
        let(:id) { 1 }
        run_test!
      end

      response '404', 'no encontrado' do
        let(:Authorization) { 'Bearer <token>' }
        let(:id) { 9_999 }
        run_test!
      end
    end

    put 'Actualiza un artículo (cambia datos; primera asignación de persona si estaba sin asignar)' do
      tags 'Articles'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        properties: {
          articulo: {
            type: :object,
            properties: {
              identificador:     { type: :string,  nullable: true, example: 'ART-9999' },
              fecha_ingreso:     { type: :string,  nullable: true, format: :date, example: '2025-09-22' },
              modelo_id:         { type: :integer, nullable: true },
              marca_id:          { type: :integer, nullable: true }, # valida pertenencia del modelo
              persona_actual_id: { type: :integer, nullable: true }  # solo si el artículo estaba sin asignar
            }
          }
        },
        required: [ 'articulo' ]
      }

      response '200', 'ok (devuelve show)' do
        let(:Authorization) { 'Bearer <token>' }
        let(:id) { 1 }
        let(:body) { { articulo: { identificador: 'ART-9999' } } }
        run_test!
      end

      response '422', 'el artículo ya tiene portador (usar /transfers para cambiarlo)' do
        let(:Authorization) { 'Bearer <token>' }
        let(:id) { 1 }
        let(:body) { { articulo: { persona_actual_id: 3 } } } # si ya tenía otro
        run_test!
      end

      response '404', 'no encontrado' do
        let(:Authorization) { 'Bearer <token>' }
        let(:id) { 9_999 }
        let(:body) { { articulo: { identificador: 'X' } } }
        run_test!
      end
    end

    delete 'Elimina/archiva un artículo (si tuvo uso, se desasigna y se inactiva; si no, se borra)' do
      tags 'Articles'
      produces 'application/json'

      response '204', 'no content' do
        let(:Authorization) { 'Bearer <token>' }
        let(:id) { 1 }
        run_test!
      end

      response '404', 'no encontrado' do
        let(:Authorization) { 'Bearer <token>' }
        let(:id) { 9_999 }
        run_test!
      end
    end
  end
end
