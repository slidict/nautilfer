# frozen_string_literal: true

require_relative 'base'
require 'uri'

class Nautilfer
  module Adapters
    class Chatwork < Base
      API_ENDPOINT = "https://api.chatwork.com/v2"

      def initialize(api_token:)
        @api_token = api_token
      end

      def headers
        {
          'X-ChatWorkToken' => api_token,
          'Content-Type' => 'application/x-www-form-urlencoded'
        }
      end

      def payload(message)
        { body: message }
      end

      def body(payload)
        URI.encode_www_form(payload)
      end

      private

      attr_reader :api_token
    end
  end
end
