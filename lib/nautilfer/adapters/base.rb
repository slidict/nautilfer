# frozen_string_literal: true

class Nautilfer
  module Adapters
    class Base
      def headers
        { 'Content-Type' => 'application/json' }
      end

      def payload(_message)
        raise NotImplementedError, "Adapters must implement #payload"
      end

      def body(payload)
        payload.to_json
      end
    end
  end
end
