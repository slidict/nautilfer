# frozen_string_literal: true

require_relative "nautilfer/version"
require_relative "nautilfer/adapters/base"
require_relative "nautilfer/adapters/teams"
require_relative "nautilfer/adapters/slack"
require_relative "nautilfer/adapters/chatwork"
require "json/add/core"
require "net/http"
require "uri"

class Nautilfer
  class Error < StandardError; end

  class Configuration
    attr_accessor :environment, :enabled_environments, :disabled_environments

    def initialize
      @enabled_environments = []
      @disabled_environments = []
    end
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.reset_configuration!
    @configuration = Configuration.new
  end

  def initialize(endpoint:, adapter: Adapters::Teams.new, environment: nil, enabled_environments: nil, disabled_environments: nil)
    config = self.class.configuration

    @endpoint = URI.parse(endpoint)
    @adapter = resolve_adapter(adapter)
    @environment = environment || config.environment || ENV['NAUTILFER_ENV'] || ENV['RAILS_ENV'] || ENV['RACK_ENV']
    @enabled_environments = normalize_env_list(enabled_environments, config.enabled_environments)
    @disabled_environments = normalize_env_list(disabled_environments, config.disabled_environments)
  end

  def notify(message)
    return if notifications_disabled?

    payload, headers = build_payload(message)
    perform_request(payload, headers)
  end

  private

  attr_reader :endpoint, :adapter, :environment, :enabled_environments, :disabled_environments

  def resolve_adapter(adapter)
    resolved_adapter =
      case adapter
      when Symbol
        adapter_from_symbol(adapter)
      when Class
        adapter.new
      else
        adapter
      end

    validate_adapter!(resolved_adapter)
  end

  def adapter_from_symbol(adapter)
    case adapter
    when :teams
      Adapters::Teams.new
    when :slack
      Adapters::Slack.new
    when :chatwork
      Adapters::Chatwork.new(api_token: ENV.fetch('CHATWORK_API_TOKEN') { raise Error, 'CHATWORK_API_TOKEN is required for chatwork adapter' })
    else
      raise Error, "Unsupported adapter: #{adapter}"
    end
  end

  def validate_adapter!(adapter)
    return adapter if adapter.respond_to?(:payload) && adapter.respond_to?(:headers) && adapter.respond_to?(:body)

    raise Error, "Unsupported adapter: #{adapter.inspect}"
  end

  def normalize_env_list(custom_value, configured_value)
    Array(custom_value.nil? ? configured_value : custom_value).compact
  end

  def notifications_disabled?
    return true if disabled_environments.include?(environment)
    return false if enabled_environments.empty?

    !enabled_environments.include?(environment)
  end

  def build_payload(message)
    [adapter.payload(message), adapter.headers]
  end

  def perform_request(payload, headers)
    http = Net::HTTP.new(endpoint.host, endpoint.port)
    http.use_ssl = endpoint.scheme == 'https'
    http.start do |connection|
      request = Net::HTTP::Post.new(endpoint.request_uri, headers)
      request.body = adapter.body(payload)
      connection.request(request)
    end
  end
end
