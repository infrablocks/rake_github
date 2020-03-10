require 'rake_factory'
require 'octokit'

module RakeGithub
  module Tasks
    module DeployKey
      class Destroy < RakeFactory::Task
        default_name :destroy
        default_description RakeFactory::DynamicValue.new { |t|
          "Destroys deploy key from the #{t.repository} repository"
        }

        parameter :repository, required: true
        parameter :access_token, required: true
        parameter :title, required: true

        action do |t|
          client = Octokit::Client.new(access_token: access_token)

          print "Removing deploy key '#{t.title}' from the " +
              "'#{t.repository}' repository... "
          deploy_keys = client.list_deploy_keys(t.repository)
          deploy_key = deploy_keys.find { |k| k[:title] == t.title }
          client.remove_deploy_key(t.repository, deploy_key[:id]) if deploy_key
          puts "Done."
        end
      end
    end
  end
end
