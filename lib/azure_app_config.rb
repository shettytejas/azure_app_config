# frozen_string_literal: true

require_relative "azure_app_config/base"

module AzureAppConfig
  VERSION = "1.1.0"

  class InvalidTypeError < StandardError; end
  class ExceededLimitError < StandardError; end
  class UnallowedValueError < StandardError; end
  class NotFoundError < StandardError; end
end
