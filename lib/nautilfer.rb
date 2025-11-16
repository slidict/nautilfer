# frozen_string_literal: true

require_relative "nautilfer/version"
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

  def initialize(endpoint:, adapter: :teams, environment: nil, enabled_environments: nil, disabled_environments: nil)
    config = self.class.configuration

    @endpoint = URI.parse(endpoint)
    @adapter = adapter
    @environment = environment || config.environment || ENV['NAUTILFER_ENV'] || ENV['RAILS_ENV'] || ENV['RACK_ENV']
    @enabled_environments = normalize_env_list(enabled_environments, config.enabled_environments)
    @disabled_environments = normalize_env_list(disabled_environments, config.disabled_environments)
  end

  def notify(message)
    return if notifications_disabled?

    payload, headers = build_payload(message)
    perform_request(payload, headers)
  end

  def self.to_teams(message:, endpoint:, environment: nil, enabled_environments: nil, disabled_environments: nil)
    new(
      endpoint: endpoint,
      adapter: :teams,
      environment: environment,
      enabled_environments: enabled_environments,
      disabled_environments: disabled_environments
    ).notify(message)
  end

  def self.to_slack(message:, endpoint:, environment: nil, enabled_environments: nil, disabled_environments: nil)
    new(
      endpoint: endpoint,
      adapter: :slack,
      environment: environment,
      enabled_environments: enabled_environments,
      disabled_environments: disabled_environments
    ).notify(message)
  end

  private

  attr_reader :endpoint, :adapter, :environment, :enabled_environments, :disabled_environments

  def normalize_env_list(custom_value, configured_value)
    Array(custom_value.nil? ? configured_value : custom_value).compact
  end

  def notifications_disabled?
    return true if disabled_environments.include?(environment)
    return false if enabled_environments.empty?

    !enabled_environments.include?(environment)
  end

  def build_payload(message)
    case adapter
    when :teams
      [teams_payload(message), default_headers]
    when :slack
      [slack_payload(message), default_headers]
    else
      raise Error, "Unsupported adapter: #{adapter}"
    end
  end

  def default_headers
    { 'Content-Type' => 'application/json' }
  end

  def perform_request(payload, headers)
    http = Net::HTTP.new(endpoint.host, endpoint.port)
    http.use_ssl = endpoint.scheme == 'https'
    http.start do |connection|
      request = Net::HTTP::Post.new(endpoint.request_uri, headers)
      request.body = payload.to_json
      connection.request(request)
    end
  end

  def teams_payload(message)
    {
      "attachments": [
        {
          "contentType": "application/vnd.microsoft.card.adaptive",
          "content": {
            "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
            "type": "AdaptiveCard",
            "version": "1.2",
            "body": [
              {
                "type": "TextBlock",
                "text": message,
                "wrap": true,
                "markdown": true
              }
            ]
          }
        }
      ]
    }
  end

  def slack_payload(message)
    {
      "text": message
    }
  end
end
