require "swagger_helper"

RSpec.describe "api/v1/people", type: :request do
  include_context "api_auth"

  let!(:persona) { Persona.create!(nombre: "Ana", apellido: "García", identificador: "ID-00112233") }
  let!(:marca)   { Marca.create!(nombre: "Apple") }
  let!(:modelo)  { Modelo.create!(marca:, nombre: "MacBook Air", anio: 2024) }
  let!(:articulo_asignado) do
    Articulo.create!(identificador: "ART-P1", fecha_ingreso: Date.today, modelo:, persona_actual: persona)
  end

  path "/api/v1/people" do
    parameter name: "Authorization", in: :header, schema: { type: :string }, required: true
    let(:Authorization) { "Bearer #{api_user.api_token}" }

    get "Lista personas" do
      tags "People"
      produces "application/json"
      response "200", "ok" do
        run_test!
      end
    end

    post "Crear persona" do
      tags "People"
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        properties: { persona: { type: :object } },
        required: [ "persona" ]
      }

        response "201", "created" do
        let(:body) { { persona: { nombre: "Bruno", apellido: "Pérez", identificador: "ID-BRU-001" } } }
        run_test!
        end


      response "422", "datos inválidos" do
        let(:body) { { persona: { nombre: "" } } }
        run_test!
      end
    end
  end

  path "/api/v1/people/{id}" do
    parameter name: "Authorization", in: :header, schema: { type: :string }, required: true
    let(:Authorization) { "Bearer #{api_user.api_token}" }
    parameter name: :id, in: :path, required: true, schema: { type: :integer }

    get "Mostrar persona" do
      tags "People"
      produces "application/json"

      response "200", "ok" do
        let(:id) { persona.id }
        run_test!
      end

      response "404", "no encontrada" do
        let(:id) { 9_999 }
        run_test!
      end
    end

    put "Actualizar persona" do
      tags "People"
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        properties: { persona: { type: :object } },
        required: [ "persona" ]
      }

      response "200", "ok" do
        let(:id)   { persona.id }
        let(:body) { { persona: { nombre: "Ana María" } } }
        run_test!
      end

      response "404", "no encontrada" do
        let(:id)   { 9_999 }
        let(:body) { { persona: { nombre: "X" } } }
        run_test!
      end
    end

    delete "Eliminar persona" do
      tags "People"
      produces "application/json"

      response "204", "no content" do
        let(:id) { persona.id }
        run_test!
      end

      response "404", "no encontrada" do
        let(:id) { 9_999 }
        run_test!
      end
    end
  end

  path "/api/v1/people/{id}/articles" do
    parameter name: "Authorization", in: :header, schema: { type: :string }, required: true
    let(:Authorization) { "Bearer #{api_user.api_token}" }
    parameter name: :id, in: :path, required: true, schema: { type: :integer }

    get "Artículos de una persona" do
      tags "People"
      produces "application/json"

      response "200", "ok" do
        let(:id) { persona.id }
        run_test!
      end

      response "404", "persona no encontrada" do
        let(:id) { 9_999 }
        run_test!
      end
    end
  end
end
