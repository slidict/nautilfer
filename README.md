# nautilfer

[![Gem Version](https://badge.fury.io/rb/nautilfer.svg)](https://badge.fury.io/rb/nautilfer)
[![Build Status](https://github.com/slidict/nautilfer/actions/workflows/main.yml/badge.svg)](https://github.com/slidict/nautilfer/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

`nautilfer` is a gem that allows you to parse and analyze web pages, extracting key statistics and information for further use within your projects.

## Requirements

- Ruby >= 3.4

## Installation

Add this line to your application's Gemfile:


```ruby
gem 'nautilfer'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install nautilfer
```

### Resolving UID Mismatch Between Docker and Host

To resolve issues related to the difference between Docker's UID and the host's UID, add the following line to your .bashrc or similar shell configuration file:

```bash
export UID=${UID}
```

This will ensure that the environment variable UID is correctly set in your Docker containers, matching your host system's user ID.

This explanation provides clear instructions on how to resolve the UID mismatch issue using the export command.

## Usage
To use nautilfer, first require it.

```ruby
require 'nautilfer'
```

Instantiate Nautilfer with the adapter you want to use:

```ruby
notifier = Nautilfer.new(endpoint: "#{workflow_endpoint}", adapter: Nautilfer::Adapters::Teams.new)
notifier.notify("## TEST\nhello")
```

To notify a Slack channel via Incoming Webhook:

```ruby
slack_notifier = Nautilfer.new(endpoint: "#{slack_webhook_url}", adapter: Nautilfer::Adapters::Slack.new)
slack_notifier.notify("Deployment completed")
```

### Control notifications by environment

Use the environment controls to avoid sending notifications in non-production environments. The notifier checks the `environment` you pass in (defaulting to `ENV['NAUTILFER_ENV']`, `ENV['RAILS_ENV']`, or `ENV['RACK_ENV']`) and will only send messages when the environment is allowed.

Enable notifications only in specific environments:

```ruby
notifier = Nautilfer.new(
  endpoint: "#{workflow_endpoint}",
  adapter: Nautilfer::Adapters::Teams.new,
  environment: 'production',
  enabled_environments: ['production']
)
notifier.notify("Release deployed")
```

Or disable notifications for certain environments:

```ruby
slack_notifier = Nautilfer.new(
  endpoint: "#{slack_webhook_url}",
  adapter: Nautilfer::Adapters::Slack.new,
  environment: 'test',
  disabled_environments: ['test', 'development']
)
slack_notifier.notify("Smoke tests running")
```

### Configure defaults once

Persist your environment preferences by configuring defaults up front. New instances will reuse these values unless you override them per call.

```ruby
Nautilfer.configure do |config|
  config.environment = ENV['NAUTILFER_ENV']
  config.enabled_environments = ['production']
  config.disabled_environments = ['test']
end

notifier = Nautilfer.new(endpoint: "#{workflow_endpoint}", adapter: :teams)
notifier.notify("Deployment finished")
```

### Configure message templates

Define reusable message templates in the global configuration and select them when instantiating a notifier. Templates are callables that receive the original message and return the formatted text.

```ruby
Nautilfer.configure do |config|
  config.message_templates = {
    default: ->(message) { "[default] #{message}" },
    headline: ->(message) { "## #{message}" }
  }

  config.default_message_template = :default
end

notifier = Nautilfer.new(endpoint: "#{workflow_endpoint}", adapter: :slack)
notifier.notify("Deployment finished") # => sends "[default] Deployment finished"

headline_notifier = Nautilfer.new(endpoint: "#{workflow_endpoint}", adapter: :slack, message_template: :headline)
headline_notifier.notify("Deployment finished") # => sends "## Deployment finished"
```

## Chatwork Notification Integration

To enable Chatwork notifications using the unified adapter interface, initialize `Nautilfer` with the Chatwork adapter and tar
get a room-specific endpoint:

```ruby
endpoint = "https://api.chatwork.com/v2/rooms/#{room_id}/messages"
notifier = Nautilfer.new(
  endpoint: endpoint,
  adapter: Nautilfer::Adapters::Chatwork.new(api_token: ENV['CHATWORK_API_TOKEN'])
)
notifier.notify('This is a test message from Nautilfer!')
```

You can also pass `adapter: :chatwork` when `CHATWORK_API_TOKEN` is set in your environment.

## Features
- More features coming soon!

## Commit Message Guidelines

To ensure consistency and facilitate automatic updates to the `CHANGELOG.md`, please follow the [Conventional Commits](https://www.conventionalcommits.org/) specification when creating commit messages. This helps maintain a clear and structured commit history.

When submitting a Pull Request (PR), make sure your commits adhere to these guidelines.

### Example of Conventional Commit Messages:

- `feat: add new feature for parsing web pages`
- `fix: resolve issue with URL redirection`
- `docs: update README with usage instructions`
- `chore: update dependencies`
- `build: update build configuration`
- `ci: update CI pipeline`
- `style: fix code style issues`
- `refactor: refactor code for better readability`
- `perf: improve performance of data processing`
- `test: add new tests for URL parsing module`

By following these guidelines, you help ensure that our project's commit history is easy to navigate and that versioning and release notes are generated correctly.

## Contributing
Bug reports and pull requests are welcome on GitHub at https://github.com/slidict/nautilfer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the Contributor Covenant code of conduct.

## License
The gem is available as open-source under the terms of the MIT License.

## Acknowledgments
Special thanks to all the contributors and open-source projects that make this possible.
