# frozen_string_literal: true

require_relative 'lib/slack_unfurling'
require_relative 'lib/github_client'

def lambda_handler(event:, context:)
  SlackUnfurling.new(GitHubClient.new).call(event)
end
