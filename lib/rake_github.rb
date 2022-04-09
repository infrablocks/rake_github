# frozen_string_literal: true

require 'rake_github/version'
require 'rake_github/tasks'
require 'rake_github/task_sets'

module RakeGithub
  def self.define_deploy_keys_tasks(opts = {}, &block)
    RakeGithub::TaskSets::DeployKeys.define(opts, &block)
  end

  def self.define_repository_tasks(opts = {}, &block)
    RakeGithub::TaskSets::Repository.define(opts, &block)
  end

  def self.define_release_task(opts = {}, &block)
    RakeGithub::Tasks::Releases::Create.define(opts, &block)
  end
end
