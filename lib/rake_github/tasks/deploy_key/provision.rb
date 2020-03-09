require 'rake_factory'

module RakeGithub
  module Tasks
    module DeployKey
      class Provision < RakeFactory::Task
        default_name :provision
        default_description RakeFactory::DynamicValue.new { |t|
          "Provision deploy key to the #{t.repository} repository"
        }

        parameter :repository, required: true
        parameter :access_token, required: true
        parameter :title, required: true
        parameter :public_key, required: true
        parameter :read_only, default: false

        action do |t|
          client = Octokit::Client.new(access_token: access_token)

          print "Adding deploy key '#{t.title}' to the " +
              "'#{t.repository}' repository... "
          client.add_deploy_key(
              t.repository,
              t.title,
              t.public_key,
              read_only: t.read_only)
          puts "Done."
        end
      end
    end
  end
end
