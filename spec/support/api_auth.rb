RSpec.shared_context "api_auth" do
  let!(:api_user) do
    u = User.find_or_initialize_by(email_address: "api-rswag@example.com")
    if u.new_record?
      u.password = "apitest123"
      u.role     = :admin
      u.save!
    end
    u.regenerate_api_token if u.api_token.blank?
    u
  end

  let(:Authorization) { "Bearer #{api_user.api_token}" }
end
