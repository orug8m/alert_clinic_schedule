# frozen_string_literal: true

require 'slack-ruby-client'

Slack.configure do |config|
  config.token = ENV.fetch('SLACK_API_TOKEN', nil)
end
