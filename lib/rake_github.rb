# frozen_string_literal: true

require 'rake_github/exceptions'
require 'rake_github/version'
require 'rake_github/tasks'
require 'rake_github/task_sets'

module RakeGithub
  def self.define_deploy_keys_tasks(opts = {}, &)
    RakeGithub::TaskSets::DeployKeys.define(opts, &)
  end

  def self.define_repository_tasks(opts = {}, &)
    RakeGithub::TaskSets::Repository.define(opts, &)
  end

  def self.define_release_task(opts = {}, &)
    RakeGithub::Tasks::Releases::Create.define(opts, &)
  end
end
