# frozen_string_literal: true

require_relative 'base'

class Nautilfer
  module Adapters
    class Teams < Base
      def payload(message)
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
    end
  end
end
