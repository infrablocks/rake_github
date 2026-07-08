# frozen_string_literal: true

require 'rake_factory'
require 'octokit'

module RakeGithub
  module Tasks
    module Secrets
      class Destroy < RakeFactory::Task
        default_name :destroy
        default_description(RakeFactory::DynamicValue.new do |t|
          "Destroys secrets from the #{t.repository} repository"
        end)

        parameter :repository, required: true
        parameter :access_token, required: true
        parameter :secrets, default: []

        action do |t|
          client = Octokit::Client.new(access_token:)

          $stdout.puts 'Removing specified secrets from the ' \
                       "'#{t.repository}' repository... "
          t.secrets.each do |secret|
            $stdout.print "Removing '#{secret[:name]}'... "
            delete_actions_secret(client, t.repository, secret[:name])
            delete_dependabot_secret(client, t.repository, secret[:name])
            $stdout.puts 'Done.'
          end
        end

        private

        def delete_actions_secret(client, repository, name)
          client.delete_actions_secret(repository, name)
        rescue Octokit::NotFound
          nil
        end

        def delete_dependabot_secret(client, repository, name)
          client.delete_dependabot_secret(repository, name)
        rescue Octokit::NotFound
          nil
        end
      end
    end
  end
end
