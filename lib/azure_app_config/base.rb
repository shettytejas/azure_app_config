# frozen_string_literal: true

require_relative "client"

require "json"
require "singleton"

# TODO: Consider pagination

module AzureAppConfig
  class Base
    include Singleton

    def initialize
      @key_prefix = ENV.fetch("AZURE_APP_CONFIG_KEY_PREFIX", ".appconfig.featureflag/")
      @client = AzureAppConfig::Client.new
    end

    def all(name: nil, label: nil)
      name, label = normalise_parameters(name: name, label: label)
      path = "/kv"

      query_params = URI.encode_www_form(key: name.map { |n| "#{key_prefix}#{n}" }.join(","), label: label.join(","))

      parse_list_response client.get(path, query_params)
    end

    def fetch(name, label: nil)
      name, label = normalise_fetch_parameters(name: name, label: label)
      path = "/kv/#{key_prefix}#{name}"

      query_params = URI.encode_www_form(label: label)
      response = client.get(path, query_params)

      raise AzureAppConfig::NotFoundError if response.code.to_i == 404

      parse_fetch_response response
    end

    def labels(name: nil)
      name, _ = normalise_parameters(name: name, label: nil)
      path = "/labels"

      query_params = URI.encode_www_form(name: name.join(","))
      parse_labels_response client.get(path, query_params)
    end

    def keys(name: nil)
      name, = normalise_parameters(name: name, label: nil)
      path = "/keys"

      query_params = URI.encode_www_form(name: name.map { |n| "#{key_prefix}#{n}" }.join(","))

      parse_keys_response client.get(path, query_params)
    end

    def enabled?(name, label: nil)
      fetch(name, label: label)["value"]["enabled"]
    rescue AzureAppConfig::NotFoundError
      false
    end

    def disabled?(name, label: nil)
      !enabled?(name, label: label)
    end

    def self.method_missing(name, *args, **kwargs, &block)
      return super unless instance_methods.include?(name)

      instance.public_send(name, *args, **kwargs, &block)
    end

    def self.respond_to_missing?(name, include_private = false)
      instance.respond_to?(name, include_private) || super
    end

    private

    attr_reader :key_prefix, :client

    def normalise_parameters(name:, label:)
      name = name.to_s if name.nil?
      label = label.to_s if label.nil?

      name = name.split(",") if name.is_a?(String)
      label = label.split(",") if label.is_a?(String)

      raise AzureAppConfig::InvalidTypeError, "name must be a valid array" unless name.is_a?(Array)
      raise AzureAppConfig::InvalidTypeError, "label must be a valid array" unless label.is_a?(Array)

      name = ["*"] if name.empty?
      label = ["*"] if label.empty?

      raise AzureAppConfig::ExceededLimitError, "values present in name array exceeds count of 5" if name.length > 5
      raise AzureAppConfig::ExceededLimitError, "values present in label array exceeds count of 5" if label.length > 5

      [name, label]
    end

    def normalise_fetch_parameters(name:, label:)
      name = name.to_s if name.nil?
      label = label.to_s if label.nil?

      raise AzureAppConfig::InvalidTypeError, "name must be a valid string" unless name.is_a?(String)
      raise AzureAppConfig::InvalidTypeError, "label must be a valid string" unless label.is_a?(String)

      raise AzureAppConfig::InvalidTypeError, "name should not be comma separated" if name.include?(",")
      raise AzureAppConfig::InvalidTypeError, "label should not be comma separated" if label.include?(",")

      [name, label]
    end

    def parse_list_response(response)
      data = JSON.parse(response.body)
      data["items"].each { |item| item["value"] = JSON.parse(item["value"]) }

      data["items"]
    end

    def parse_fetch_response(response)
      data = JSON.parse(response.body)
      data["value"] = JSON.parse(data["value"])

      data
    end

    def parse_keys_response(response)
      data = JSON.parse(response.body)
      data["items"].map { |item| item["name"].gsub(key_prefix, "") }
    end

    def parse_labels_response(response)
      JSON.parse(response.body)["items"].map { |item| item["name"] }
    end
  end
end
