# frozen_string_literal: true

require 'rake_factory'

require_relative '../tasks'

module RakeGithub
  module TaskSets
    class Environments < RakeFactory::TaskSet
      prepend RakeFactory::Namespaceable

      parameter :repository, required: true
      parameter :access_token, required: true
      parameter :environments, default: []

      parameter :destroy_task_name, default: :destroy
      parameter :provision_task_name, default: :provision
      parameter :ensure_task_name, default: :ensure

      task Tasks::Environments::Provision,
           name: RakeFactory::DynamicValue.new { |ts|
             ts.provision_task_name
           }
      task Tasks::Environments::Destroy,
           name: RakeFactory::DynamicValue.new { |ts|
             ts.destroy_task_name
           }
      task Tasks::Environments::Ensure,
           name: RakeFactory::DynamicValue.new { |ts|
             ts.ensure_task_name
           }
    end
  end
end
