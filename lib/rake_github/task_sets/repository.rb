require 'rake_factory'

require_relative '../tasks'

module RakeGithub
  module TaskSets
    class Repository < RakeFactory::TaskSet
      prepend RakeFactory::Namespaceable

      parameter :repository, required: true
      parameter :access_token, required: true
      parameter :deploy_keys, default: []

      parameter :deploy_keys_namespace, default: :deploy_keys
      parameter :deploy_keys_destroy_task_name, default: :destroy
      parameter :deploy_keys_provision_task_name, default: :provision
      parameter :deploy_keys_ensure_task_name, default: :ensure
      parameter :branch_name
      parameter :commit_message, default: ''

      task Tasks::DeployKeys::Provision,
          name: RakeFactory::DynamicValue.new { |ts|
            ts.deploy_keys_provision_task_name
          }
      task Tasks::DeployKeys::Destroy,
          name: RakeFactory::DynamicValue.new { |ts|
            ts.deploy_keys_destroy_task_name
          }
      task Tasks::DeployKeys::Ensure,
          name: RakeFactory::DynamicValue.new { |ts|
            ts.deploy_keys_ensure_task_name
          },
          provision_task_name: RakeFactory::DynamicValue.new { |ts|
            ts.deploy_keys_provision_task_name
          },
          destroy_task_name: RakeFactory::DynamicValue.new { |ts|
            ts.deploy_keys_destroy_task_name
          }
      task Tasks::PullRequests::Merge,
          argument_names: [:branch_name, :commit_message],
          branch_name: RakeFactory::DynamicValue.new { |ts|
            ts.branch_name
          },
          commit_message: RakeFactory::DynamicValue.new { |ts|
            ts.commit_message
          }

      def define_on(application)
        around_define(application) do
          self.class.tasks.each do |task_definition|
            ns = case task_definition.klass.to_s
            when /DeployKeys/
              deploy_keys_namespace
            when /PullRequests/
              :pull_requests
            else
              nil
            end

            application.in_namespace(ns) do
              task_definition
                  .for_task_set(self)
                  .define_on(application)
            end
          end
        end
      end
    end
  end
end
