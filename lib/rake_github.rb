require 'rake_github/version'
require 'rake_github/tasks'
require 'rake_github/task_sets'

module RakeGithub
  def self.define_deploy_keys_tasks(opts = {}, &block)
    RakeGithub::TaskSets::DeployKeys.define(opts, &block)
  end
end
