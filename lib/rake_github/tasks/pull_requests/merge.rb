# frozen_string_literal: true

require 'rake_factory'
require 'octokit'

require_relative '../../exceptions/no_pull_request'
require_relative '../../exceptions/required_argument_unset'

module RakeGithub
  module Tasks
    module PullRequests
      class Merge < RakeFactory::Task
        default_description(RakeFactory::DynamicValue.new do |t|
          'Merges pull request on the specified branch in the ' \
            "#{t.repository} repository"
        end)

        parameter :default_argument_names,
                  default: %i[branch_name commit_message]

        parameter :repository, required: true
        parameter :access_token, required: true

        def argument_names
          @argument_names + default_argument_names
        end

        action do |t, args|
          branch_name = resolve_branch_name(args)
          commit_message = resolve_commit_message(args)

          client = Octokit::Client.new(access_token:)

          open_prs = client.pull_requests(t.repository)
          current_pr = open_prs.find { |pr| pr[:head][:ref] == branch_name }

          # rubocop:disable Style/RaiseArgs
          raise Exceptions::NoPullRequest.new(branch_name) if current_pr.nil?
          # rubocop:enable Style/RaiseArgs

          client.merge_pull_request(
            t.repository,
            current_pr[:number],
            format(commit_message, current_pr[:title])
          )
        end

        private

        def resolve_branch_name(args)
          if !args.branch_name || args.branch_name.strip.empty?
            raise(
              Exceptions::RequiredArgumentUnset,
              'Must provide a branch name argument.'
            )
          end

          args.branch_name.strip
        end

        def resolve_commit_message(args)
          if !args.commit_message || args.commit_message.strip.empty?
            '%s'
          else
            args.commit_message.strip
          end
        end
      end
    end
  end
end
