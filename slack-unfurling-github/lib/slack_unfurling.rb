# frozen_string_literal: true

require 'json'
require_relative './slack_api_client'

class SlackUnfurling
  def initialize(client)
    @client = client
  end

  attr_reader :client

  def call(event)
    params = JSON.parse(event["body"])

    case params['type']
    when 'url_verification'
      challenge = params['challenge']
      if client.enabled?
        { statusCode: 200, body: JSON.generate(challenge: challenge) }
      else
        { statusCode: 404, body: JSON.generate(ok: false) }
      end
    when 'event_callback'
      channel = params.dig('event', 'channel')
      ts = params.dig('event', 'message_ts')
      links = params.dig('event', 'links')

      unfurls = {}
      links.each do |link|
        url = link['url']

        next unless client.target?(url)

        unfurls[url] = client.get(url)
      end

      payload = JSON.generate(
        channel: channel,
        ts: ts,
        unfurls: unfurls
      )

      slackApiClient = SlackApiClient.new
      slackApiClient.request(payload)
      { statusCode: 200, body: JSON.generate(ok: true) }
    end
  end
end
