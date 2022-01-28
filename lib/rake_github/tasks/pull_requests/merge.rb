# frozen_string_literal: true

require 'rake_factory'
require 'octokit'

require_relative '../../exceptions/no_pull_request_error'

module RakeGithub
  module Tasks
    module PullRequests
      class Merge < RakeFactory::Task
        default_description(RakeFactory::DynamicValue.new do |t|
          'Merges pull request on the specified branch in the ' \
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

          # rubocop:disable Style/RaiseArgs
          raise Exceptions::NoPullRequestError.new(t.branch_name) if current_pr.nil?
          # rubocop:enable Style/RaiseArgs

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
