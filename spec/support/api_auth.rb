RSpec.shared_context "api_auth" do
  let!(:api_user) do
    User.find_or_create_by!(email_address: "spec@example.com") do |u|
      u.password = "specpass123"
      u.role = :admin
    end.tap { |u| u.regenerate_api_token if u.api_token.blank? }
  end

  # Para request specs
  let(:auth_headers) { { "Authorization" => "Bearer #{api_user.api_token}" } }
end
