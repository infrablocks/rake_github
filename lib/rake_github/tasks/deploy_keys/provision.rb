require 'rake_factory'
require 'octokit'

module RakeGithub
  module Tasks
    module DeployKeys
      class Provision < RakeFactory::Task
        default_name :provision
        default_description(RakeFactory::DynamicValue.new { |t|
          "Provision deploy keys to the #{t.repository} repository"
        })

        parameter :repository, required: true
        parameter :access_token, required: true
        parameter :deploy_keys, default: []

        action do |t|
          client = Octokit::Client.new(access_token: access_token)

          puts "Adding specified deploy keys to the " +
              "'#{t.repository}' repository... "
          t.deploy_keys.each do |deploy_key|
            print "Adding '#{deploy_key[:title]}'... "
            client.add_deploy_key(
                t.repository,
                deploy_key[:title],
                deploy_key[:public_key],
                read_only: !!deploy_key[:read_only])
            puts "Done."
          end
        end
      end
    end
  end
end
