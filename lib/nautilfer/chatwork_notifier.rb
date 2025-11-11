require 'net/http'
require 'uri'
require 'json'

class Nautilfer
  class ChatworkNotifier
    CHATWORK_API_ENDPOINT = "https://api.chatwork.com/v2"

    def initialize(api_token, room_id)
      @api_token = api_token
      @room_id = room_id
    end

    def notify(message)
      uri = URI("#{CHATWORK_API_ENDPOINT}/rooms/#{@room_id}/messages")
      request = Net::HTTP::Post.new(uri)
      request['X-ChatWorkToken'] = @api_token
      request.set_form_data(body: message)

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      raise "Failed to send notification: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    end
  end
end
