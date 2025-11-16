# spec/nautilfer_spec.rb
require 'spec_helper'

RSpec.describe Nautilfer do
  it "has a version number" do
    expect(Nautilfer::VERSION).not_to be nil
  end

  describe '#notify' do
    let(:message) { "Instance message" }
    let(:endpoint) { "https://example.com/webhook" }

    context 'when adapter is teams' do
      let(:notifier) { described_class.new(endpoint: endpoint, adapter: :teams) }

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

      it 'sends a POST request with the Teams payload' do
        notifier.notify(message)
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

    context 'when adapter is slack' do
      let(:notifier) { described_class.new(endpoint: endpoint, adapter: :slack) }

      before do
        stub_request(:post, endpoint)
          .with(
            body: { "text" => message }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
          .to_return(status: 200, body: "", headers: {})
      end

      it 'sends a POST request with the Slack payload' do
        notifier.notify(message)
        expect(WebMock).to have_requested(:post, endpoint).with(
          body: { "text" => message }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        ).once
      end
    end

    context 'when the environment is not enabled' do
      let(:notifier) do
        described_class.new(
          endpoint: endpoint,
          adapter: :teams,
          environment: 'development',
          enabled_environments: ['production']
        )
      end

      it 'does not send a notification' do
        notifier.notify(message)

        expect(WebMock).not_to have_requested(:post, endpoint)
      end
    end

    context 'when the environment is explicitly disabled' do
      let(:notifier) do
        described_class.new(
          endpoint: endpoint,
          adapter: :teams,
          environment: 'staging',
          disabled_environments: ['staging']
        )
      end

      it 'does not send a notification' do
        notifier.notify(message)

        expect(WebMock).not_to have_requested(:post, endpoint)
      end
    end
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

    it 'does not send a request when environment is not enabled' do
      Nautilfer.to_teams(
        message: message,
        endpoint: endpoint,
        environment: 'development',
        enabled_environments: ['production']
      )

      expect(WebMock).not_to have_requested(:post, endpoint)
    end
  end

  describe '.to_slack' do
    let(:message) { "Slack message" }
    let(:endpoint) { "https://example.com/slack/webhook" }

    before do
      stub_request(:post, endpoint)
        .with(
          body: { "text" => message }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        .to_return(status: 200, body: "", headers: {})
    end

    it 'sends a POST request to the specified slack endpoint with the correct payload' do
      Nautilfer.to_slack(message: message, endpoint: endpoint)
      expect(WebMock).to have_requested(:post, endpoint).with(
        body: { "text" => message }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      ).once
    end

    it 'does not send a request when environment is disabled' do
      Nautilfer.to_slack(
        message: message,
        endpoint: endpoint,
        environment: 'test',
        disabled_environments: ['test']
      )

      expect(WebMock).not_to have_requested(:post, endpoint)
    end
  end

  describe '.configure' do
    let(:message) { "Configured message" }
    let(:teams_endpoint) { "https://example.com/configured/teams" }
    let(:slack_endpoint) { "https://example.com/configured/slack" }

    after do
      described_class.reset_configuration!
    end

    context 'when environment is enabled globally' do
      before do
        Nautilfer.configure do |config|
          config.environment = 'production'
          config.enabled_environments = ['production']
        end

        stub_request(:post, teams_endpoint)
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

        stub_request(:post, slack_endpoint)
          .with(
            body: { "text" => message }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
          .to_return(status: 200, body: "", headers: {})
      end

      it 'applies configuration to instances' do
        notifier = Nautilfer.new(endpoint: teams_endpoint, adapter: :teams)
        notifier.notify(message)

        expect(WebMock).to have_requested(:post, teams_endpoint).once
      end

      it 'applies configuration to helper methods' do
        Nautilfer.to_slack(message: message, endpoint: slack_endpoint)

        expect(WebMock).to have_requested(:post, slack_endpoint).once
      end
    end

    context 'when environment is disabled globally' do
      before do
        Nautilfer.configure do |config|
          config.environment = 'development'
          config.disabled_environments = ['development']
        end

        stub_request(:post, teams_endpoint)
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

      it 'skips notifications when configuration disables the environment' do
        notifier = Nautilfer.new(endpoint: teams_endpoint, adapter: :teams)
        notifier.notify(message)

        expect(WebMock).not_to have_requested(:post, teams_endpoint)
      end
    end
  end
end
