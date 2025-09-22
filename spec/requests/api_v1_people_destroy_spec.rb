require "rails_helper"

RSpec.describe "API::V1::People#destroy", type: :request do
  let!(:user)    { create(:user) }
  let(:headers)  { { "Authorization" => "Bearer #{user.api_token}" } }

  context "cuando la persona tiene transferencias" do
    it "archiva la persona, cierra la transferencia abierta y suelta los artículos" do
      p = create(:person)
      art = create(:article, persona_actual: p)
      # transferencia abierta (sin fecha_fin)
      t = create(:transferencia, articulo: art, persona: p, fecha_inicio: Date.new(2025, 9, 1), fecha_fin: nil)

      delete "/api/v1/people/#{p.id}", headers: headers
      expect(response).to have_http_status(:no_content)

      expect(PERSONA = Persona.find(p.id).archivado).to be true
      expect(Articulo.find(art.id).persona_actual_id).to be_nil

      t.reload
      expect(t.fecha_fin).not_to be_nil
      expect(t.descripcion.to_s).to match(/cerrada por archivado de persona/i)
    end
  end

  context "cuando la persona no tiene transferencias" do
    it "borra el registro (no content)" do
      p = create(:person)
      delete "/api/v1/people/#{p.id}", headers: headers
      expect(response).to have_http_status(:no_content)
      expect(Persona.where(id: p.id)).not_to exist
    end
  end
end
