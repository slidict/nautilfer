require 'spec_helper'
RSpec.describe Nautilfer::Adapters::Chatwork do
  let(:api_token) { 'test_token' }
  let(:room_id) { '123456' }
  let(:endpoint) { "#{described_class::API_ENDPOINT}/rooms/#{room_id}/messages" }
  let(:adapter) { described_class.new(api_token: api_token) }

  describe '#payload and #headers' do
    it 'builds form-encoded data with token header' do
      notifier = Nautilfer.new(endpoint: endpoint, adapter: adapter)

      stub_request(:post, endpoint)
        .with(
          headers: {
            'X-ChatWorkToken' => api_token,
            'Content-Type' => 'application/x-www-form-urlencoded'
          },
          body: 'body=Test+message'
        )
        .to_return(status: 200, body: '{}')

      notifier.notify('Test message')

      expect(WebMock).to have_requested(:post, endpoint)
        .with(headers: {
          'X-ChatWorkToken' => api_token,
          'Content-Type' => 'application/x-www-form-urlencoded'
        })
        .with(body: 'body=Test+message')
    end
  end

  describe 'adapter resolution via symbol' do
    before { @original_token = ENV['CHATWORK_API_TOKEN'] }
    after { ENV['CHATWORK_API_TOKEN'] = @original_token }

    it 'uses CHATWORK_API_TOKEN to initialize the adapter' do
      ENV['CHATWORK_API_TOKEN'] = api_token
      notifier = Nautilfer.new(endpoint: endpoint, adapter: :chatwork)

      stub_request(:post, endpoint)
        .with(headers: {
          'X-ChatWorkToken' => api_token,
          'Content-Type' => 'application/x-www-form-urlencoded'
        })
        .to_return(status: 200, body: '{}')

      notifier.notify('Hello chatwork')

      expect(WebMock).to have_requested(:post, endpoint)
        .with(headers: {
          'X-ChatWorkToken' => api_token,
          'Content-Type' => 'application/x-www-form-urlencoded'
        })
    end
    end
  end
