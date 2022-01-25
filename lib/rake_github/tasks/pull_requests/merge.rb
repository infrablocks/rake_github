# frozen_string_literal: true

require 'rake_factory'
require 'octokit'
require 'git'

module RakeGithub
  module Tasks
    module PullRequests
      class Merge < RakeFactory::Task
        default_description(RakeFactory::DynamicValue.new do |t|
          "Merges pull request on the current branch in the #{t.repository} repository"
        end)

        parameter :repository, required: true
        parameter :access_token, required: true
        parameter :commit_message, default: ''

        action do |t|
          current_branch = Git.open(Pathname.new('.')).current_branch
          github_client = Octokit::Client.new(access_token: access_token)

          open_prs = github_client.pull_requests(t.repository)

          current_pr = open_prs
            .find { |pr| pr[:head][:ref] == current_branch }

          raise NoPullRequestError.new current_branch if current_pr.nil?

          github_client.merge_pull_request(
            t.repository,
            current_pr[:number],
            format(t.commit_message % current_pr[:title])
          )
        end
      end
    end
  end
end

class NoPullRequestError < StandardError
  attr_reader :branch_name
  def initialize(branch_name)
    @branch_name = branch_name
  end

  def message
    "No pull request associated with branch %s" % branch_name
  end
end