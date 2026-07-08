# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'

describe RakeGithub::TaskSets::Environments do
  include_context 'rake'

  def define_tasks(opts = {}, &block)
    described_class.define({
      access_token: 'some-token',
      repository: 'org/repo'
    }.merge(opts), &block)
  end

  it 'adds all environments tasks in the provided namespace ' \
     'when supplied' do
    define_tasks(namespace: :environments)

    expect(Rake.application)
      .to(have_tasks_defined(
            %w[environments:provision
               environments:destroy
               environments:ensure]
          ))
  end

  it 'adds all environments tasks in the root namespace when none supplied' do
    define_tasks

    expect(Rake.application)
      .to(have_tasks_defined(
            %w[provision
               destroy
               ensure]
          ))
  end

  describe 'destroy task' do
    it 'configures with the provided repository' do
      repository = 'my-org/my-repo'

      define_tasks(
        repository:
      )

      rake_task = Rake::Task['destroy']

      expect(rake_task.creator.repository).to(eq(repository))
    end

    it 'configures with the provided access token' do
      access_token = 'some-access-token'

      define_tasks(
        access_token:
      )

      rake_task = Rake::Task['destroy']

      expect(rake_task.creator.access_token).to(eq(access_token))
    end

    it 'uses a name of destroy by default' do
      define_tasks

      expect(Rake.application)
        .to(have_task_defined('destroy'))
    end

    it 'uses the provided name when supplied' do
      define_tasks(destroy_task_name: :destroy_it_all)

      expect(Rake.application)
        .to(have_task_defined('destroy_it_all'))
    end

    it 'has no environments by default' do
      define_tasks

      rake_task = Rake::Task['destroy']

      expect(rake_task.creator.environments).to(eq([]))
    end

    it 'uses the provided environments when supplied' do
      environments = [
        { name: 'release' }
      ]
      define_tasks(
        environments:
      )

      rake_task = Rake::Task['destroy']

      expect(rake_task.creator.environments).to(eq(environments))
    end
  end

  describe 'provision task' do
    it 'configures with the provided repository' do
      repository = 'my-org/my-repo'

      define_tasks(
        repository:
      )

      rake_task = Rake::Task['provision']

      expect(rake_task.creator.repository).to(eq(repository))
    end

    it 'configures with the provided access token' do
      access_token = 'some-access-token'

      define_tasks(
        access_token:
      )

      rake_task = Rake::Task['provision']

      expect(rake_task.creator.access_token).to(eq(access_token))
    end

    it 'uses a name of provision by default' do
      define_tasks

      expect(Rake.application)
        .to(have_task_defined('provision'))
    end

    it 'uses the provided name when supplied' do
      define_tasks(provision_task_name: :provision_things)

      expect(Rake.application)
        .to(have_task_defined('provision_things'))
    end

    it 'has no environments by default' do
      define_tasks

      rake_task = Rake::Task['provision']

      expect(rake_task.creator.environments).to(eq([]))
    end

    it 'uses the provided environments when supplied' do
      environments = [
        { name: 'release' }
      ]
      define_tasks(
        environments:
      )

      rake_task = Rake::Task['provision']

      expect(rake_task.creator.environments).to(eq(environments))
    end
  end

  describe 'ensure task' do
    it 'configures with the provided repository' do
      repository = 'my-org/my-repo'

      define_tasks(
        repository:
      )

      rake_task = Rake::Task['ensure']

      expect(rake_task.creator.repository).to(eq(repository))
    end

    it 'uses a name of ensure by default' do
      define_tasks

      expect(Rake.application)
        .to(have_task_defined('ensure'))
    end

    it 'uses the provided name when supplied' do
      define_tasks(ensure_task_name: :make_sure)

      expect(Rake.application)
        .to(have_task_defined('make_sure'))
    end

    it 'uses a destroy task name of destroy by default' do
      define_tasks

      rake_task = Rake::Task['ensure']

      expect(rake_task.creator.destroy_task_name)
        .to(eq(:destroy))
    end

    it 'uses the provided destroy task name when supplied' do
      define_tasks(destroy_task_name: :destroy_it_all)

      rake_task = Rake::Task['ensure']

      expect(rake_task.creator.destroy_task_name)
        .to(eq(:destroy_it_all))
    end

    it 'uses a provision task name of provision by default' do
      define_tasks

      rake_task = Rake::Task['ensure']

      expect(rake_task.creator.provision_task_name)
        .to(eq(:provision))
    end

    it 'uses the provided provision task name when supplied' do
      define_tasks(provision_task_name: :provision_some_things)

      rake_task = Rake::Task['ensure']

      expect(rake_task.creator.provision_task_name)
        .to(eq(:provision_some_things))
    end
  end
end
