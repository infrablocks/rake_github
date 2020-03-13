require 'rake_factory'

module RakeGithub
  module Tasks
    module DeployKeys
      class Ensure < RakeFactory::Task
        default_name :ensure
        default_description RakeFactory::DynamicValue.new { |t|
          "Ensure deploy keys are configured on the " +
              "#{t.repository} repository"
        }

        parameter :repository, required: true

        parameter :provision_task_name, default: :provision
        parameter :destroy_task_name, default: :destroy

        action do |t, args|
          t.application[t.destroy_task_name, t.scope].invoke(*args)
          t.application[t.provision_task_name, t.scope].invoke(*args)
        end
      end
    end
  end
end
