# frozen_string_literal: true

require 'rake_factory'
require 'octokit'

module RakeGithub
  module Tasks
    module DeployKeys
      class Destroy < RakeFactory::Task
        default_name :destroy
        default_description(RakeFactory::DynamicValue.new do |t|
          "Destroys deploy keys from the #{t.repository} repository"
        end)

        parameter :repository, required: true
        parameter :access_token, required: true
        parameter :deploy_keys, default: []

        action do |t|
          client = Octokit::Client.new(access_token:)

          $stdout.puts 'Removing specified deploy keys from the ' \
                       "'#{t.repository}' repository... "
          all_deploy_keys = client.list_deploy_keys(t.repository)
          t.deploy_keys.each do |deploy_key|
            $stdout.print "Removing '#{deploy_key[:title]}' key... "
            matching_deploy_key =
              all_deploy_keys.find { |k| k[:title] == deploy_key[:title] }
            if matching_deploy_key
              client.remove_deploy_key(t.repository, matching_deploy_key[:id])
            end
            $stdout.puts 'Done.'
          end
        end
      end
    end
  end
end
