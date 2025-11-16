# frozen_string_literal: true

require_relative 'base'

class Nautilfer
  module Adapters
    class Slack < Base
      def payload(message)
        {
          "text": message
        }
      end
    end
  end
end
