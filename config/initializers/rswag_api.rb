Rswag::Api.configure do |c|
  c.openapi_root = Rails.root.join("swagger").to_s

  c.swagger_filter = lambda do |swagger, env|
    host = env["HTTP_HOST"]
    scheme = env["rack.url_scheme"]
    swagger["servers"] = [ { "url" => "#{scheme}://#{host}" } ]
  end
end
