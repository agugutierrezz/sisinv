require "rails_helper"

RSpec.describe "API::V1::Transfers errores", type: :request do
  let!(:user)    { create(:user) }
  let(:headers)  { { "Authorization" => "Bearer #{user.api_token}" } }
  let!(:art)     { create(:article, persona_actual: nil) }
  let!(:p1)      { create(:person) }

  it "400 si falta el wrapper 'transferencia'" do
    post "/api/v1/transfers",
         params: { articulo_id: art.id, persona_id: p1.id, fecha_inicio: "2025-09-01" }, 
         headers: headers

    expect(response).to have_http_status(:bad_request)
  end
end
