# frozen_string_literal: true

require 'octokit'

class GitHubClient
  PR_URL_PATTERN = /\Ahttps:\/\/github\.com\/(.+)\/pull\/(\d+)(\/.*)?\z/.freeze

  def initialize
    @client = Octokit::Client.new(access_token: ENV['GITHUB_PERSONAL_ACCESS_TOKEN'])
  end

  def enabled?
    ENV['GITHUB_PERSONAL_ACCESS_TOKEN']
  end

  def target?(url)
    url =~ PR_URL_PATTERN
  end

  def get(url)
    return nil unless url =~ PR_URL_PATTERN

    begin
      pr = @client.pull_request($1, $2.to_i)

      info = {
        title: "##{pr.number} #{pr.title}",
        title_link: pr.html_url,
        author_name: pr.user.login,
        author_icon: pr.user.avatar_url,
        author_link: pr.user.html_url,
        color: '#dddddd',
        fields: [
          {
              title: 'Repo',
              value: $1,
              short: true
          },
          {
              title: 'Status',
              value: pr.state.upcase,
              short: true
          }
        ]
      }

      return info
    rescue
      nil
    end
  end

end

