require 'swagger_helper'

RSpec.describe 'api/v1/models', type: :request do
  path '/api/v1/models' do
    get 'Lista modelos' do
      tags 'Models'
      produces 'application/json'
      parameter name: :Authorization, in: :header, schema: { type: :string }, required: true
      parameter name: :marca_id, in: :query, schema: { type: :integer }, required: false
      parameter name: :q,        in: :query, schema: { type: :string },  required: false
      parameter name: :anio,     in: :query, schema: { type: :integer }, required: false

      response '200', 'ok' do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer #{user.api_token}" }
        before do
          acer  = create(:brand, nombre: 'Acer')
          apple = create(:brand, nombre: 'Apple')
          create(:model, marca: acer,  nombre: 'Swift 3', anio: 2022)
          create(:model, marca: apple, nombre: 'MacBook Air', anio: 2024)
        end
        run_test!
      end
    end

    post 'Crea modelo' do
      tags 'Models'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :Authorization, in: :header, schema: { type: :string }, required: true
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          modelo: {
            type: :object,
            properties: {
              nombre:   { type: :string },
              anio:     { type: :integer },
              marca_id: { type: :integer }
            },
            required: %w[nombre anio marca_id]
          }
        },
        required: [ 'modelo' ]
      }

      response '201', 'created' do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer #{user.api_token}" }
        let(:brand) { create(:brand) }
        let(:body) { { modelo: { nombre: 'Swift X', anio: 2023, marca_id: brand.id } } }
        run_test!
      end
    end
  end

  path '/api/v1/models/{id}' do
    parameter name: :id, in: :path, schema: { type: :integer }
    parameter name: :Authorization, in: :header, schema: { type: :string }, required: true

    get 'Muestra modelo' do
      tags 'Models'
      produces 'application/json'
      response '200', 'ok' do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer #{user.api_token}" }
        let(:id) { create(:model, marca: create(:brand)).id }
        run_test!
      end
    end

    put 'Actualiza modelo' do
      tags 'Models'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          modelo: {
            type: :object,
            properties: {
              nombre:   { type: :string },
              anio:     { type: :integer },
              marca_id: { type: :integer }
            },
            required: %w[nombre anio marca_id]
          }
        },
        required: [ 'modelo' ]
      }

      response '200', 'ok' do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer #{user.api_token}" }
        let(:brand) { create(:brand) }
        let(:id) { create(:model, marca: brand, nombre: 'Old', anio: 2020).id }
        let(:body) { { modelo: { nombre: 'New', anio: 2021, marca_id: brand.id } } }
        run_test!
      end
    end

    delete 'Borra modelo' do
      tags 'Models'
      produces 'application/json'
      response '204', 'no content' do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer #{user.api_token}" }
        let(:id) { create(:model, marca: create(:brand)).id }
        run_test!
      end
    end
  end
end
