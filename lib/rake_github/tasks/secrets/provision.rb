# frozen_string_literal: true

require 'base64'
require 'rake_factory'
require 'octokit'

module RakeGithub
  module Tasks
    module Secrets
      class Provision < RakeFactory::Task
        default_name :provision
        default_description(RakeFactory::DynamicValue.new do |t|
          "Provision secrets to the #{t.repository} repository"
        end)

        parameter :repository, required: true
        parameter :access_token, required: true
        parameter :secrets, default: []

        action do |t|
          client = Octokit::Client.new(access_token:)

          $stdout.puts 'Provisioning specified secrets on the ' \
                       "'#{t.repository}' repository... "
          provision_actions_secrets(client, t)
          provision_dependabot_secrets(client, t)
        end

        private

        def provision_actions_secrets(client, task)
          public_key = client.get_actions_public_key(task.repository)
          task.secrets.each do |secret|
            $stdout.print "Adding '#{secret[:name]}' to Actions... "
            client.create_or_update_actions_secret(
              task.repository,
              secret[:name],
              secret_options(public_key, secret[:value])
            )
            $stdout.puts 'Done.'
          end
        end

        def provision_dependabot_secrets(client, task)
          public_key = client.get_dependabot_public_key(task.repository)
          task.secrets.each do |secret|
            $stdout.print "Adding '#{secret[:name]}' to Dependabot... "
            client.create_or_update_dependabot_secret(
              task.repository,
              secret[:name],
              secret_options(public_key, secret[:value])
            )
            $stdout.puts 'Done.'
          end
        end

        def secret_options(public_key, value)
          {
            key_id: public_key.key_id,
            encrypted_value: encrypt(public_key.key, value)
          }
        end

        def encrypt(base64_public_key, value)
          require 'rbnacl'

          decoded_key = Base64.decode64(base64_public_key)
          box = RbNaCl::Boxes::Sealed.from_public_key(
            RbNaCl::PublicKey.new(decoded_key)
          )
          Base64.strict_encode64(box.encrypt(value))
        end
      end
    end
  end
end
