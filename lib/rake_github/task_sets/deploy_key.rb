require 'rake_factory'

require_relative '../tasks'

module RakeGithub
  module TaskSets
    class DeployKey < RakeFactory::TaskSet
      prepend RakeFactory::Namespaceable

      parameter :repository, required: true
      parameter :title, required: true
      parameter :access_token, required: true
      parameter :public_key, required: true

      parameter :destroy_task_name, default: :destroy
      parameter :provision_task_name, default: :provision
      parameter :ensure_task_name, default: :ensure

      task Tasks::DeployKey::Provision,
          name: RakeFactory::DynamicValue.new { |ts|
            ts.provision_task_name
          }
      task Tasks::DeployKey::Destroy,
          name: RakeFactory::DynamicValue.new { |ts|
            ts.destroy_task_name
          }
      task Tasks::DeployKey::Ensure,
          name: RakeFactory::DynamicValue.new { |ts|
            ts.ensure_task_name
          }
    end
  end
end
