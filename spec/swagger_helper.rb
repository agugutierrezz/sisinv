require 'rails_helper'

RSpec.configure do |config|
    config.openapi_root = Rails.root.join('swagger').to_s
    config.openapi_specs = {
    "v1/swagger.yaml" => {
        openapi: "3.0.3",
        info: { title: "SisInv API", version: "v1" },
        servers: [ { url: "/" } ],
        components: {
        securitySchemes: {
            bearerAuth: { type: :http, scheme: :bearer, bearerFormat: :JWT }
        }
        },
        security: [ { bearerAuth: [] } ],
        paths: {}
    }
    }
    config.swagger_format = :yaml
end
