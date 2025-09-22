require "rails_helper"

RSpec.describe "API::V1::Transfers required fields", type: :request do
    let!(:user)    { create(:user) }
    let(:headers)  { { "Authorization" => "Bearer #{user.api_token}" } }
    let!(:art)     { create(:article, persona_actual: nil) }

    it "404 si falta persona_id dentro del wrapper 'transferencia'" do
        post "/api/v1/transfers",
            params: { transferencia: { articulo_id: art.id, fecha_inicio: "2025-09-01" } },
            headers: headers
        expect(response).to have_http_status(:not_found)
    end
end
