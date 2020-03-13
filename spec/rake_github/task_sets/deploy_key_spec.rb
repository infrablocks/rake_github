require 'spec_helper'
require 'fileutils'

describe RakeGithub::TaskSets::DeployKeys do
  include_context :rake

  def define_tasks(opts = {}, &block)
    subject.define({
        access_token: 'some-token',
        repository: 'org/repo'
    }.merge(opts), &block)
  end

  it 'adds all deploy key tasks in the provided namespace ' +
      'when supplied' do
    define_tasks(namespace: :deploy_keys)

    expect(Rake::Task.task_defined?('deploy_keys:provision'))
        .to(be(true))
    expect(Rake::Task.task_defined?('deploy_keys:destroy'))
        .to(be(true))
    expect(Rake::Task.task_defined?('deploy_keys:ensure'))
        .to(be(true))
  end

  it 'adds all deploy key tasks in the root namespace when none supplied' do
    define_tasks

    expect(Rake::Task.task_defined?('provision')).to(be(true))
    expect(Rake::Task.task_defined?('destroy')).to(be(true))
    expect(Rake::Task.task_defined?('ensure')).to(be(true))
  end

  context 'destroy task' do
    it 'configures with the provided repository and access token' do
      repository = 'my-org/my-repo'
      access_token = 'some-access-token'

      define_tasks(
          repository: repository,
          access_token: access_token)

      rake_task = Rake::Task["destroy"]

      expect(rake_task.creator.repository).to(eq(repository))
      expect(rake_task.creator.access_token).to(eq(access_token))
    end

    it 'uses a name of destroy by default' do
      define_tasks

      expect(Rake::Task.task_defined?("destroy")).to(be(true))
    end

    it 'uses the provided name when supplied' do
      define_tasks(destroy_task_name: :destroy_it_all)

      expect(Rake::Task.task_defined?("destroy_it_all"))
          .to(be(true))
    end

    it 'has no deploy keys by default' do
      define_tasks

      rake_task = Rake::Task["destroy"]

      expect(rake_task.creator.deploy_keys).to(eq([]))
    end

    it 'uses the provided deploy keys when supplied' do
      deploy_keys = [
          {
              title: 'the-deploy-key',
              public_key: File.read('spec/fixtures/2.public')
          }
      ]
      define_tasks(
          deploy_keys: deploy_keys)

      rake_task = Rake::Task["destroy"]

      expect(rake_task.creator.deploy_keys).to(eq(deploy_keys))
    end
  end

  context 'provision task' do
    it 'configures with the provided repository and access token' do
      repository = 'my-org/my-repo'
      access_token = 'some-access-token'

      define_tasks(
          repository: repository,
          access_token: access_token)

      rake_task = Rake::Task["provision"]

      expect(rake_task.creator.repository).to(eq(repository))
      expect(rake_task.creator.access_token).to(eq(access_token))
    end

    it 'uses a name of provision by default' do
      define_tasks

      expect(Rake::Task.task_defined?("provision")).to(be(true))
    end

    it 'uses the provided name when supplied' do
      define_tasks(provision_task_name: :provision_things)

      expect(Rake::Task.task_defined?("provision_things"))
          .to(be(true))
    end

    it 'has no deploy keys by default' do
      define_tasks

      rake_task = Rake::Task["provision"]

      expect(rake_task.creator.deploy_keys).to(eq([]))
    end

    it 'uses the provided deploy keys when supplied' do
      deploy_keys = [
          {
              title: 'the-deploy-key',
              public_key: File.read('spec/fixtures/2.public')
          }
      ]
      define_tasks(
          deploy_keys: deploy_keys)

      rake_task = Rake::Task["provision"]

      expect(rake_task.creator.deploy_keys).to(eq(deploy_keys))
    end
  end

  context 'ensure task' do
    it 'configures with the provided repository' do
      repository = 'my-org/my-repo'

      define_tasks(
          repository: repository)

      rake_task = Rake::Task["ensure"]

      expect(rake_task.creator.repository).to(eq(repository))
    end

    it 'uses a name of ensure by default' do
      define_tasks

      expect(Rake::Task.task_defined?("ensure")).to(be(true))
    end

    it 'uses the provided name when supplied' do
      define_tasks(ensure_task_name: :make_sure)

      expect(Rake::Task.task_defined?("make_sure"))
          .to(be(true))
    end

    it 'uses a destroy task name of destroy by default' do
      define_tasks

      rake_task = Rake::Task["ensure"]

      expect(rake_task.creator.destroy_task_name)
          .to(eq(:destroy))
    end

    it 'uses the provided destroy task name when supplied' do
      define_tasks(destroy_task_name: :destroy_it_all)

      rake_task = Rake::Task["ensure"]

      expect(rake_task.creator.destroy_task_name)
          .to(eq(:destroy_it_all))
    end

    it 'uses a provision task name of provision by default' do
      define_tasks

      rake_task = Rake::Task["ensure"]

      expect(rake_task.creator.provision_task_name)
          .to(eq(:provision))
    end

    it 'uses the provided provision task name when supplied' do
      define_tasks(provision_task_name: :provision_some_things)

      rake_task = Rake::Task["ensure"]

      expect(rake_task.creator.provision_task_name)
          .to(eq(:provision_some_things))
    end
  end
end
