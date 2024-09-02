# frozen_string_literal: true

require_relative "nautilfer/version"
require "json/add/core"
require "net/http"

module Nautilfer
  class Error < StandardError; end
  def self.to_teams(message:, endpoint:)
    message = {
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

    uri = URI.parse(endpoint)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.start do |h|
      request = Net::HTTP::Post.new(uri.request_uri, { 'Content-Type' => 'application/json' })
      request.body = message.to_json
      h.request(request)
    end
  end
end
