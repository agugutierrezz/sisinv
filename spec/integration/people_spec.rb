require 'swagger_helper'

RSpec.describe 'api/v1/people', type: :request do
  path '/api/v1/people' do
    get 'Lista personas' do
      tags 'People'
      produces 'application/json'
      parameter name: :Authorization, in: :header, required: true, schema: { type: :string }
      parameter name: :per,       in: :query, required: false, schema: { type: :integer, example: 12 }
      parameter name: :page,      in: :query, required: false, schema: { type: :integer, example: 1 }
      parameter name: :archivado, in: :query, required: false, schema: { type: :boolean, example: false }
      parameter name: :q,         in: :query, required: false, schema: { type: :string,  example: 'gonza' }
      parameter name: :nombre,    in: :query, required: false, schema: { type: :string,  example: 'Gonzalo' }
      parameter name: :apellido,  in: :query, required: false, schema: { type: :string,  example: 'Pérez' }

      response '200', 'ok' do
        let(:Authorization) { 'Bearer <token>' }
        run_test!
      end
    end

    post 'Crea persona' do
      tags 'People'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :Authorization, in: :header, required: true, schema: { type: :string }
      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        properties: {
          persona: {
            type: :object,
            properties: {
              nombre:        { type: :string, example: 'Ana' },
              apellido:      { type: :string, example: 'Vivas' },
              identificador: { type: :string, example: 'ID-0001' }
            },
            required: %w[nombre apellido]
          }
        },
        required: [ 'persona' ]
      }

      response '201', 'created' do
        let(:Authorization) { 'Bearer <token>' }
        let(:body) { { persona: { nombre: 'Ana', apellido: 'Vivas', identificador: 'ID-0001' } } }
        run_test!
      end

      response '422', 'datos inválidos' do
        let(:Authorization) { 'Bearer <token>' }
        let(:body) { { persona: { nombre: '', apellido: '' } } }
        run_test!
      end
    end
  end

  path '/api/v1/people/{id}' do
    parameter name: :id, in: :path, required: true, schema: { type: :integer }
    parameter name: :Authorization, in: :header, required: true, schema: { type: :string }

    get 'Muestra persona' do
      tags 'People'
      produces 'application/json'

      response '200', 'ok' do
        let(:Authorization) { 'Bearer <token>' }
        let(:id) { 1 }
        run_test!
      end

      response '404', 'no encontrada' do
        let(:Authorization) { 'Bearer <token>' }
        let(:id) { 9_999 }
        run_test!
      end
    end

    put 'Actualiza persona' do
      tags 'People'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        properties: {
          persona: {
            type: :object,
            properties: {
              nombre:        { type: :string, example: 'Ana' },
              apellido:      { type: :string, example: 'Vivas' },
              identificador: { type: :string, example: 'ID-0002' }
            }
          }
        },
        required: [ 'persona' ]
      }

      response '200', 'ok' do
        let(:Authorization) { 'Bearer <token>' }
        let(:id) { 1 }
        let(:body) { { persona: { nombre: 'Ana', apellido: 'Vivas', identificador: 'ID-0002' } } }
        run_test!
      end

      response '404', 'no encontrada' do
        let(:Authorization) { 'Bearer <token>' }
        let(:id) { 9_999 }
        let(:body) { { persona: { nombre: 'X' } } }
        run_test!
      end
    end

    delete 'Elimina/archiva persona' do
      tags 'People'
      produces 'application/json'

      response '204', 'no content' do
        let(:Authorization) { 'Bearer <token>' }
        let(:id) { 1 }
        run_test!
      end

      response '404', 'no encontrada' do
        let(:Authorization) { 'Bearer <token>' }
        let(:id) { 9_999 }
        run_test!
      end
    end
  end

  path '/api/v1/people/{id}/articles' do
    parameter name: :id, in: :path, required: true, schema: { type: :integer }
    parameter name: :Authorization, in: :header, required: true, schema: { type: :string }
    parameter name: :per,  in: :query, required: false, schema: { type: :integer, example: 12 }
    parameter name: :page, in: :query, required: false, schema: { type: :integer, example: 1 }

    get 'Historial de artículos (tuvo o tiene)' do
      tags 'People'
      produces 'application/json'

      response '200', 'ok' do
        let(:Authorization) { 'Bearer <token>' }
        let(:id) { 1 }
        run_test!
      end

      response '404', 'persona no encontrada' do
        let(:Authorization) { 'Bearer <token>' }
        let(:id) { 9_999 }
        run_test!
      end
    end
  end
end
