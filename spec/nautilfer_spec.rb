# spec/nautilfer_spec.rb
require 'spec_helper'

RSpec.describe Nautilfer do
  it "has a version number" do
    expect(Nautilfer::VERSION).not_to be nil
  end

  describe '.to_teams' do
    let(:message) { "Test message" }
    let(:endpoint) { "https://example.com/webhook" }

    before do
      stub_request(:post, endpoint)
        .with(
          body: {
            "attachments" => [
              {
                "contentType" => "application/vnd.microsoft.card.adaptive",
                "content" => {
                  "$schema" => "http://adaptivecards.io/schemas/adaptive-card.json",
                  "type" => "AdaptiveCard",
                  "version" => "1.2",
                  "body" => [
                    {
                      "type" => "TextBlock",
                      "text" => message,
                      "wrap" => true,
                      "markdown" => true
                    }
                  ]
                }
              }
            ]
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        .to_return(status: 200, body: "", headers: {})
    end

    it 'sends a POST request to the specified endpoint with the correct payload' do
      Nautilfer.to_teams(message: message, endpoint: endpoint)
      expect(WebMock).to have_requested(:post, endpoint).with(
        body: {
          "attachments" => [
            {
              "contentType" => "application/vnd.microsoft.card.adaptive",
              "content" => {
                "$schema" => "http://adaptivecards.io/schemas/adaptive-card.json",
                "type" => "AdaptiveCard",
                "version" => "1.2",
                "body" => [
                  {
                    "type" => "TextBlock",
                    "text" => message,
                    "wrap" => true,
                    "markdown" => true
                  }
                ]
              }
            }
          ]
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      ).once
    end
  end
end
