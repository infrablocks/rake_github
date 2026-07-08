# frozen_string_literal: true

require 'rake_factory'
require 'octokit'

module RakeGithub
  module Tasks
    module Environments
      class Destroy < RakeFactory::Task
        default_name :destroy
        default_description(RakeFactory::DynamicValue.new do |t|
          "Destroys environments from the #{t.repository} repository"
        end)

        parameter :repository, required: true
        parameter :access_token, required: true
        parameter :environments, default: []

        action do |t|
          client = Octokit::Client.new(access_token:)

          $stdout.puts 'Removing specified environments from the ' \
                       "'#{t.repository}' repository... "
          t.environments.each do |environment|
            $stdout.print "Removing '#{environment[:name]}'... "
            delete_environment(client, t.repository, environment[:name])
            $stdout.puts 'Done.'
          end
        end

        private

        def delete_environment(client, repository, name)
          client.delete_environment(repository, name)
        rescue Octokit::NotFound
          nil
        end
      end
    end
  end
end
