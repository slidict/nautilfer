#### テストファイル `spec/lib/nautilfer/chatwork_notifier_spec.rb`
```ruby
require 'nautilfer/chatwork_notifier'

RSpec.describe Nautilfer::ChatworkNotifier do
  let(:api_token) { "test_token" }
  let(:room_id) { "123456" }
  let(:notifier) { described_class.new(api_token, room_id) }

  describe '#notify' do
    it 'sends a notification successfully' do
      stub_request(:post, "https://api.chatwork.com/v2/rooms/#{room_id}/messages")
        .with(
          headers: { 'X-ChatWorkToken' => api_token },
          body: { body: "Test message" }
        )
        .to_return(status: 200, body: '{"message_id": "7890"}', headers: {})

      response = notifier.notify("Test message")
      expect(response['message_id']).to eq("7890")
    end

    it 'raises an error for a failed request' do
      stub_request(:post, "https://api.chatwork.com/v2/rooms/#{room_id}/messages")
        .to_return(status: 400, body: '{"errors":["Invalid request"]}')

      expect { notifier.notify("Test message") }.to raise_error(RuntimeError, /Failed to send notification/)
    end
  end
end
