require 'swagger_helper'

RSpec.describe 'api/v1/transfers', type: :request do
  include_context "api_auth"
  path '/api/v1/transfers' do
    post 'Crea transferencia' do
      tags 'Transfers'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :Authorization, in: :header, schema: { type: :string }, required: true
      parameter name: :body, in: :body, schema: {
        type: :object, properties: { transferencia: {
          type: :object,
          properties: {
            articulo_id:  { type: :integer },
            persona_id:   { type: :integer },
            fecha_inicio: { type: :string, format: :date_time, nullable: true },
            descripcion:  { type: :string, nullable: true }
          },
          required: %w[articulo_id persona_id]
        } },
        required: [ 'transferencia' ]
      }
      response '201', 'created' do
        let(:Authorization) { 'Bearer <token>' }
        let(:body) do
          { transferencia: { articulo_id: 1, persona_id: 1, fecha_inicio: '2025-09-22T12:00:00Z', descripcion: 'Entrega' } }
        end
        run_test!
      end
    end
  end
end
