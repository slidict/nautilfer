# spec/nautilfer_spec.rb
require 'spec_helper'

RSpec.describe Nautilfer do
  it "has a version number" do
    expect(Nautilfer::VERSION).not_to be nil
  end

  describe '#notify' do
    let(:message) { "Instance message" }
    let(:endpoint) { "https://example.com/webhook" }

    context 'when adapter is Teams' do
      let(:notifier) { described_class.new(endpoint: endpoint, adapter: Nautilfer::Adapters::Teams.new) }

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

    context 'when adapter is Slack' do
      let(:notifier) { described_class.new(endpoint: endpoint, adapter: Nautilfer::Adapters::Slack.new) }

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

    context 'when adapter is provided as a symbol' do
      let(:notifier) { described_class.new(endpoint: endpoint, adapter: :slack) }

      before do
        stub_request(:post, endpoint)
          .with(
            body: { "text" => message }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
          .to_return(status: 200, body: "", headers: {})
      end

      it 'resolves the adapter and sends a notification' do
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
          adapter: Nautilfer::Adapters::Teams.new,
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
          adapter: Nautilfer::Adapters::Teams.new,
          environment: 'staging',
          disabled_environments: ['staging']
        )
      end

      it 'does not send a notification' do
        notifier.notify(message)

        expect(WebMock).not_to have_requested(:post, endpoint)
      end
    end

    context 'when a message template is configured' do
      let(:message_templates) do
        {
          default: ->(msg) { "[default] #{msg}" },
          plain: ->(msg) { msg }
        }
      end

      before do
        Nautilfer.configure do |config|
          config.message_templates = message_templates
          config.default_message_template = :default
        end

        stub_request(:post, endpoint)
          .with(
            body: { "text" => "[default] #{message}" }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
          .to_return(status: 200, body: "", headers: {})

        stub_request(:post, "#{endpoint}/plain")
          .with(
            body: { "text" => message }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
          .to_return(status: 200, body: "", headers: {})
      end

      after do
        described_class.reset_configuration!
      end

      it 'uses the default template from configuration' do
        notifier = described_class.new(endpoint: endpoint, adapter: Nautilfer::Adapters::Slack.new)
        notifier.notify(message)

        expect(WebMock).to have_requested(:post, endpoint).with(
          body: { "text" => "[default] #{message}" }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        ).once
      end

      it 'switches templates when specified at initialization' do
        notifier = described_class.new(endpoint: "#{endpoint}/plain", adapter: Nautilfer::Adapters::Slack.new, message_template: :plain)
        notifier.notify(message)

        expect(WebMock).to have_requested(:post, "#{endpoint}/plain").with(
          body: { "text" => message }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        ).once
      end
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
        notifier = Nautilfer.new(endpoint: teams_endpoint, adapter: Nautilfer::Adapters::Teams.new)
        notifier.notify(message)

        expect(WebMock).to have_requested(:post, teams_endpoint).once
      end

      it 'applies configuration when adapter is provided as a symbol' do
        notifier = Nautilfer.new(endpoint: slack_endpoint, adapter: :slack)
        notifier.notify(message)

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
        notifier = Nautilfer.new(endpoint: teams_endpoint, adapter: Nautilfer::Adapters::Teams.new)
        notifier.notify(message)

        expect(WebMock).not_to have_requested(:post, teams_endpoint)
      end
    end
  end
end
