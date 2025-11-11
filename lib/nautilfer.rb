# frozen_string_literal: true

require_relative "nautilfer/version"
require "json/add/core"
require "net/http"
require "uri"

class Nautilfer
  class Error < StandardError; end

  def initialize(endpoint:, adapter: :teams)
    @endpoint = URI.parse(endpoint)
    @adapter = adapter
  end

  def notify(message)
    payload, headers = build_payload(message)
    perform_request(payload, headers)
  end

  def self.to_teams(message:, endpoint:)
    new(endpoint: endpoint, adapter: :teams).notify(message)
  end

  def self.to_slack(message:, endpoint:)
    new(endpoint: endpoint, adapter: :slack).notify(message)
  end

  private

  attr_reader :endpoint, :adapter

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
