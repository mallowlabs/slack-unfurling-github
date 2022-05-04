# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/stub_any_instance'
require 'webmock/minitest'

require_relative '../../app.rb'

class AppTest < Minitest::Test
  def setup
    WebMock.disable_net_connect!
  end

  def event(body)
    {
      'body' => body,
    }
  end

  def test_url_verification_404
    e = event({
      type: 'url_verification'
    }.to_json)

    expected_result = { statusCode: 404, body: JSON.generate(ok: false) }

    assert_equal(expected_result, lambda_handler(event: e, context: ''))
  end

  def test_url_verification_200
    e = event({
      type: 'url_verification',
      challenge: 'example'
    }.to_json)

    expected_result = { statusCode: 200, body: JSON.generate(challenge: 'example') }

    GitHubClient.stub_any_instance(:'enabled?', true) do
      assert_equal(expected_result, lambda_handler(event: e, context: ''))
    end
  end

  def test_event_callback_pr
    e = event({
      type: 'event_callback',
      event: {
        channel: 'channel_name',
        message_ts: '1234567890.123456',
        links: [
          { url: 'https://github.com/mallowlabs/slack-unfurling-github/pull/1' }
        ]
      }
    }.to_json)

    stub_request(:get, 'https://api.github.com/repos/mallowlabs/slack-unfurling-github/pulls/1').
      to_return(status: 200, body: {
        number: 1,
        title: 'Bump addressable from 2.6.0 to 2.8.0 in /slack-unfurling-github',
        html_url: 'https://github.com/mallowlabs/slack-unfurling-github/pull/1',
        user: {
          login: 'dependabot[bot]',
          avatar_url: 'https://avatars.githubusercontent.com/in/29110?v=4',
          html_url: 'https://github.com/apps/dependabot'
        },
        state: 'closed'
      }.to_json, headers: { content_type: 'application/json; charset=utf-8' }
    )

    stub_request(:post, 'https://slack.com/api/chat.unfurl').
      with(
        body: {
          channel: 'channel_name',
          ts: '1234567890.123456',
          unfurls: {
            'https://github.com/mallowlabs/slack-unfurling-github/pull/1': {
              title: '#1 Bump addressable from 2.6.0 to 2.8.0 in /slack-unfurling-github',
              title_link: 'https://github.com/mallowlabs/slack-unfurling-github/pull/1',
              author_name: 'dependabot[bot]',
              author_icon: 'https://avatars.githubusercontent.com/in/29110?v=4',
              author_link: 'https://github.com/apps/dependabot',
              color: '#dddddd',
              fields: [
                {
                    title: 'Repo',
                    value: 'mallowlabs/slack-unfurling-github',
                    short: true
                },
                {
                    title: 'Status',
                    value: 'CLOSED',
                    short: true
                }
              ]
            }
          }
        }.to_json
      ).to_return(status: 200, body: "", headers: {})

    expected_result = { statusCode: 200, body: JSON.generate(ok: true) }

    GitHubClient.stub_any_instance(:'enabled?', true) do
      assert_equal(expected_result, lambda_handler(event: e, context: ''))
    end
  end
end
