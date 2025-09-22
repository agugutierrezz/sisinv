require 'swagger_helper'

RSpec.describe 'api/v1/brands', type: :request do
  path '/api/v1/brands' do
    get 'Lista marcas' do
      tags 'Brands'
      produces 'application/json'
      parameter name: :Authorization, in: :header, schema: { type: :string }, required: true

      response '200', 'ok' do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer #{user.api_token}" }
        before do
          b = create(:brand, nombre: 'Apple')
          m = create(:model, marca: b, nombre: 'MacBook', anio: 2024)
          create(:article, modelo: m)
        end
        run_test!
      end
    end

    post 'Crea marca' do
      tags 'Brands'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :Authorization, in: :header, schema: { type: :string }, required: true
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          marca: {
            type: :object,
            properties: { nombre: { type: :string } },
            required: ['nombre']
          }
        },
        required: ['marca']
      }

      response '201', 'created' do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer #{user.api_token}" }
        let(:body) { { marca: { nombre: 'Dell' } } }
        run_test!
      end
    end
  end

  path '/api/v1/brands/{id}' do
    parameter name: :id, in: :path, schema: { type: :integer }
    parameter name: :Authorization, in: :header, schema: { type: :string }, required: true

    get 'Muestra marca' do
      tags 'Brands'
      produces 'application/json'

      response '200', 'ok' do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer #{user.api_token}" }
        let(:id) { create(:brand).id }
        run_test!
      end
    end

    put 'Actualiza marca' do
      tags 'Brands'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: { marca: { type: :object, properties: { nombre: { type: :string } }, required: ['nombre'] } },
        required: ['marca']
      }

      response '200', 'ok' do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer #{user.api_token}" }
        let(:id) { create(:brand, nombre: 'Old').id }
        let(:body) { { marca: { nombre: 'New' } } }
        run_test!
      end
    end

    delete 'Borra marca' do
      tags 'Brands'
      produces 'application/json'

      response '204', 'no content' do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer #{user.api_token}" }
        let(:id) { create(:brand).id }
        run_test!
      end
    end
  end
end
