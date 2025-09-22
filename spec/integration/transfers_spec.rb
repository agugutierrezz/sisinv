require "swagger_helper"

RSpec.describe "api/v1/transfers", type: :request do
  include_context "api_auth"

  let!(:p1)    { Persona.create!(nombre: "Ana",   apellido: "García") }
  let!(:p2)    { Persona.create!(nombre: "Bruno", apellido: "Pérez") }
  let!(:marca) { Marca.create!(nombre: "Lenovo") }
  let!(:modelo) { Modelo.create!(marca:, nombre: "ThinkPad T14", anio: 2023) }
  let!(:art)   { Articulo.create!(identificador: "T14-001", fecha_ingreso: Date.today, modelo:, persona_actual: p1) }

  path "/api/v1/transfers" do
    parameter name: "Authorization", in: :header, schema: { type: :string }, required: true
    let(:Authorization) { "Bearer #{api_user.api_token}" }

    post "Crear transferencia" do
      tags "Transfers"
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        properties: {
          transferencia: {
            type: :object,
            properties: {
              articulo_id:  { type: :integer },
              persona_id:   { type: :integer },
              fecha_inicio: { type: :string, format: :date }
            },
            required: %w[articulo_id persona_id fecha_inicio]
          }
        },
        required: [ "transferencia" ]
      }

      response "201", "created" do
        let(:body) do
          { transferencia: { articulo_id: art.id, persona_id: p2.id, fecha_inicio: Date.today.to_s } }
        end
        run_test!
      end
    end
  end
end
