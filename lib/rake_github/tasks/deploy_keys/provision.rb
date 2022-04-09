# frozen_string_literal: true

require 'rake_factory'
require 'octokit'

module RakeGithub
  module Tasks
    module DeployKeys
      class Provision < RakeFactory::Task
        default_name :provision
        default_description(RakeFactory::DynamicValue.new do |t|
          "Provision deploy keys to the #{t.repository} repository"
        end)

        parameter :repository, required: true
        parameter :access_token, required: true
        parameter :deploy_keys, default: []

        action do |t|
          client = Octokit::Client.new(access_token: access_token)

          $stdout.puts 'Adding specified deploy keys to the ' \
                       "'#{t.repository}' repository... "
          t.deploy_keys.each do |deploy_key|
            $stdout.print "Adding '#{deploy_key[:title]}'... "
            client.add_deploy_key(
              t.repository,
              deploy_key[:title],
              deploy_key[:public_key],
              read_only: !deploy_key[:read_only].nil?
            )
            $stdout.puts 'Done.'
          end
        end
      end
    end
  end
end
