# frozen_string_literal: true

require 'rake_factory'
require 'octokit'

module RakeGithub
  module Tasks
    module Environments
      class Provision < RakeFactory::Task
        default_name :provision
        default_description(RakeFactory::DynamicValue.new do |t|
          "Provision environments to the #{t.repository} repository"
        end)

        parameter :repository, required: true
        parameter :access_token, required: true
        parameter :environments, default: []

        action do |t|
          client = Octokit::Client.new(access_token:)
          org = t.repository.split('/').first

          $stdout.puts 'Provisioning specified environments on the ' \
                       "'#{t.repository}' repository... "
          t.environments.each do |environment|
            $stdout.print "Adding '#{environment[:name]}'... "
            client.create_or_update_environment(
              t.repository,
              environment[:name],
              environment_options(client, org, environment)
            )
            $stdout.puts 'Done.'
          end
        end

        private

        def environment_options(client, org, environment)
          {
            wait_timer: environment[:wait_timer],
            prevent_self_review: environment[:prevent_self_review],
            reviewers: resolve_reviewers(client, org, environment[:reviewers]),
            deployment_branch_policy: environment[:deployment_branch_policy]
          }.compact
        end

        def resolve_reviewers(client, org, reviewers)
          return nil if reviewers.nil?

          reviewers.map { |reviewer| resolve_reviewer(client, org, reviewer) }
        end

        def resolve_reviewer(client, org, reviewer)
          if reviewer[:team]
            { type: 'Team', id: resolve_team_id(client, org, reviewer[:team]) }
          else
            { type: 'User', id: resolve_user_id(client, reviewer[:user]) }
          end
        end

        def resolve_team_id(client, org, slug)
          team_ids[slug] ||= client.team_by_name(org, slug).id
        end

        def resolve_user_id(client, login)
          user_ids[login] ||= client.user(login).id
        end

        def team_ids
          @team_ids ||= {}
        end

        def user_ids
          @user_ids ||= {}
        end
      end
    end
  end
end
