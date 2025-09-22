require "net/http"
require "uri"
require "json"

class ApiClient
  class ConnectionError        < StandardError; end
  class Unauthorized           < StandardError; end   # 401
  class Forbidden              < StandardError; end   # 403
  class NotFound               < StandardError; end   # 404
  class UnprocessableEntity    < StandardError; end   # 422
  class ClientError            < StandardError; end   # 400–499 (resto)
  class ServerError            < StandardError; end   # 500–599

  def initialize(token: nil, host: nil)
    creds  = Rails.application.credentials
    @token = token || creds.dig(:api, :token) || ENV["API_TOKEN"]
    @host  = host  || creds.dig(:api, :host)  || ENV["API_HOST"] || "http://127.0.0.1:3000"

    # timeouts configurables (en segundos)
    @open_timeout = (ENV["API_OPEN_TIMEOUT"] || 3).to_i
    @read_timeout = (ENV["API_READ_TIMEOUT"] || 12).to_i  # ← subo el default
    @retries      = (ENV["API_RETRIES"] || 2).to_i        # ← reintentos
    raise "Falta API token" if @token.blank?
  end

  # -------- Public methods --------

  def get(path, params = {})
    request(:get, path, params: params)
  end

  def post(path, body = {})
    request(:post, path, body: body)
  end

  def put(path, body = {})
    request(:put, path, body: body)
  end

  def delete(path, params = {})
    request(:delete, path, params: params)
  end

  # -------- Internals --------

  private

  def request(method, path, params: {}, body: nil, headers: {})
    uri = URI.join(@host, path)
    uri.query = URI.encode_www_form(params) if params.present?

    req = net_http_request_for(method).new(uri)
    req["Authorization"] = "Bearer #{@token}"
    req["Accept"]        = "application/json"
    headers.each { |k, v| req[k] = v }

    if body.present?
      req["Content-Type"] = "application/json"
      req.body = ActiveSupport::JSON.encode(body)
    end

    perform(uri, req)
  end

  def net_http_request_for(method)
    case method.to_sym
    when :get    then Net::HTTP::Get
    when :post   then Net::HTTP::Post
    when :put    then Net::HTTP::Put
    when :patch  then Net::HTTP::Patch
    when :delete then Net::HTTP::Delete
    else
      raise ArgumentError, "HTTP method no soportado: #{method}"
    end
  end

  def perform(uri, req)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl      = (uri.scheme == "https")
    http.open_timeout = @open_timeout
    http.read_timeout = @read_timeout

    attempt = 0
    begin
      res = http.start { |h| h.request(req) }
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      attempt += 1
      if attempt <= @retries
        sleep(0.2 * attempt)           # backoff corto
        retry
      end
      raise ConnectionError, "API no disponible (#{e.class.name.split('::').last})"
    end

    parsed = res.body.present? ? (JSON.parse(res.body) rescue {}) : {}

    case res.code.to_i
    when 200..299
      [ res, parsed ]
    when 401 then raise Unauthorized,          api_error_message(parsed) || "No autorizado"
    when 403 then raise Forbidden,             api_error_message(parsed) || "Prohibido"
    when 404 then raise NotFound,              api_error_message(parsed) || "No encontrado"
    when 422 then raise UnprocessableEntity,   api_error_message(parsed) || "Datos inválidos"
    when 400..499
      raise ClientError, api_error_message(parsed) || "Error del cliente (#{res.code})"
    when 500..599
      raise ServerError, api_error_message(parsed) || "Error del servidor (#{res.code})"
    else
      raise ConnectionError, "Respuesta inesperada (#{res.code})"
    end
  rescue Errno::ECONNREFUSED, SocketError, Net::OpenTimeout, Net::ReadTimeout => e
    raise ConnectionError, "API no disponible (#{e.class.name.split('::').last})"
  end

  def api_error_message(parsed)
    # Normaliza mensajes típicos de tu API
    parsed["error"] ||
      (parsed["errors"].is_a?(Array) ? parsed["errors"].join(", ") : nil) ||
      parsed.dig("meta", "error")
  end
end
