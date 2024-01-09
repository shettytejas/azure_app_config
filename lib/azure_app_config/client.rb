# frozen_string_literal: true

require "base64"
require "digest"
require "net/http"
require "time"

module AzureAppConfig
  class Client
    def initialize
      @api_version = ENV.fetch("AZURE_APP_CONFIG_API_VERSION", "1.0")
      @credential = ENV.fetch("AZURE_APP_CONFIG_CREDENTIAL")
      @host = "#{ENV.fetch("AZURE_APP_CONFIG_STORE_NAME")}.azconfig.io"
      @decoded_secret = Base64.strict_decode64 ENV.fetch("AZURE_APP_CONFIG_SECRET")

      @signed_headers = "x-ms-date;host;x-ms-content-sha256"
      @url = "https://#{@host}"
    end

    def get(path, query_params = {})
      url_builder path, query_params

      request "GET", endpoint
    end

    private

    attr_reader :api_version, :credential, :host, :decoded_secret, :signed_headers, :endpoint, :url

    def url_builder(path, query_params = "")
      @endpoint = URI.parse(url)
      @endpoint.path = path
      @endpoint.query = "#{query_params}&api-version=#{api_version}"
    end

    def hmac_authentication_headers(request_path, method, content = nil)
      hashed_content = Base64.strict_encode64(Digest::SHA256.digest(content.to_s))
      timestamp = Time.now.httpdate

      raw_string = "#{method}\n#{request_path}\n#{timestamp};#{host};#{hashed_content}"
      signature = Base64.strict_encode64 OpenSSL::HMAC.digest(OpenSSL::Digest.new("sha256"), decoded_secret, raw_string)

      {
        "x-ms-date" => timestamp,
        "x-ms-content-sha256" => hashed_content,
        "Authorization" => "HMAC-SHA256 Credential=#{credential}&SignedHeaders=#{signed_headers}&Signature=#{signature}"
      }
    end

    def request(request_type, endpoint, _body = nil)
      headers = hmac_authentication_headers(endpoint.request_uri, request_type)

      case request_type
      when "GET"
        Net::HTTP.get_response(endpoint, headers)
      end
    end
  end
end
