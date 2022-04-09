# frozen_string_literal: true

require 'rake_factory'
require 'octokit'

module RakeGithub
  module Tasks
    module PullRequests
      class Merge < RakeFactory::Task
        default_description(RakeFactory::DynamicValue.new do |t|
          'Merges pull request on the specified branch in the '\
            "#{t.repository} repository"
        end)

        default_argument_names %i[branch_name commit_message]

        parameter :repository, required: true
        parameter :access_token, required: true
        parameter :branch_name, required: true
        parameter :commit_message, default: '%s'

        action do |t, _args|
          client = Octokit::Client.new(access_token: access_token)

          open_prs = client.pull_requests(t.repository)
          current_pr = open_prs.find { |pr| pr[:head][:ref] == t.branch_name }

          raise NoPullRequestError, t.branch_name if current_pr.nil?

          client.merge_pull_request(
            t.repository,
            current_pr[:number],
            format(t.commit_message, current_pr[:title])
          )
        end
      end
    end
  end
end

class NoPullRequestError < StandardError
  attr_reader :branch_name

  def initialize(branch_name)
    super()
    @branch_name = branch_name
  end

  def message
    format('No pull request associated with branch %s', branch_name)
  end
end
