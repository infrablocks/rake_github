# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'

describe RakeGithub::TaskSets::Repository do
  include_context 'rake'

  def define_tasks(opts = {}, &block)
    described_class.define({
      access_token: 'some-token',
      repository: 'org/repo'
    }.merge(opts), &block)
  end

  it 'adds all tasks in the provided namespace when supplied' do
    define_tasks(
      namespace: :github
    )

    expect(Rake.application)
      .to(have_tasks_defined(
            %w[github:deploy_keys:provision
               github:deploy_keys:destroy
               github:deploy_keys:ensure
               github:pull_requests:merge]
          ))
  end

  it 'adds all tasks in the root namespace when none supplied' do
    define_tasks

    expect(Rake.application)
      .to(have_tasks_defined(
            %w[deploy_keys:provision
               deploy_keys:destroy
               deploy_keys:ensure
               pull_requests:merge]
          ))
  end

  describe 'deploy keys tasks' do
    it 'adds all deploy key tasks in the provided namespace when supplied' do
      define_tasks(deploy_keys_namespace: :deployment_keys)

      expect(Rake.application)
        .to(have_tasks_defined(
              %w[deployment_keys:provision
                 deployment_keys:destroy
                 deployment_keys:ensure]
            ))
    end

    it 'adds all deploy key tasks in the deploy keys namespace when none ' \
       'supplied' do
      define_tasks

      expect(Rake.application)
        .to(have_tasks_defined(
              %w[deploy_keys:provision
                 deploy_keys:destroy
                 deploy_keys:ensure]
            ))
    end

    describe 'destroy task' do
      it 'configures with the provided repository' do
        repository = 'my-org/my-repo'

        define_tasks(
          repository: repository
        )

        rake_task = Rake::Task['deploy_keys:destroy']

        expect(rake_task.creator.repository).to(eq(repository))
      end

      it 'configures with the provided access token' do
        access_token = 'some-access-token'

        define_tasks(
          access_token: access_token
        )

        rake_task = Rake::Task['deploy_keys:destroy']

        expect(rake_task.creator.access_token).to(eq(access_token))
      end

      it 'uses a name of destroy by default' do
        define_tasks

        expect(Rake.application)
          .to(have_task_defined('deploy_keys:destroy'))
      end

      it 'uses the provided name when supplied' do
        define_tasks(deploy_keys_destroy_task_name: :destroy_it_all)

        expect(Rake.application)
          .to(have_task_defined('deploy_keys:destroy_it_all'))
      end

      it 'has no deploy keys by default' do
        define_tasks

        rake_task = Rake::Task['deploy_keys:destroy']

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
          deploy_keys: deploy_keys
        )

        rake_task = Rake::Task['deploy_keys:destroy']

        expect(rake_task.creator.deploy_keys).to(eq(deploy_keys))
      end
    end

    describe 'provision task' do
      it 'configures with the provided repository' do
        repository = 'my-org/my-repo'

        define_tasks(
          repository: repository
        )

        rake_task = Rake::Task['deploy_keys:provision']

        expect(rake_task.creator.repository).to(eq(repository))
      end

      it 'configures with the provided access token' do
        access_token = 'some-access-token'

        define_tasks(
          access_token: access_token
        )

        rake_task = Rake::Task['deploy_keys:provision']

        expect(rake_task.creator.access_token).to(eq(access_token))
      end

      it 'uses a name of provision by default' do
        define_tasks

        expect(Rake.application)
          .to(have_task_defined('deploy_keys:provision'))
      end

      it 'uses the provided name when supplied' do
        define_tasks(deploy_keys_provision_task_name: :provision_things)

        expect(Rake.application)
          .to(have_task_defined('deploy_keys:provision_things'))
      end

      it 'has no deploy keys by default' do
        define_tasks

        rake_task = Rake::Task['deploy_keys:provision']

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
          deploy_keys: deploy_keys
        )

        rake_task = Rake::Task['deploy_keys:provision']

        expect(rake_task.creator.deploy_keys).to(eq(deploy_keys))
      end
    end

    describe 'ensure task' do
      it 'configures with the provided repository' do
        repository = 'my-org/my-repo'

        define_tasks(
          repository: repository
        )

        rake_task = Rake::Task['deploy_keys:ensure']

        expect(rake_task.creator.repository).to(eq(repository))
      end

      it 'uses a name of ensure by default' do
        define_tasks

        expect(Rake.application)
          .to(have_task_defined('deploy_keys:ensure'))
      end

      it 'uses the provided name when supplied' do
        define_tasks(deploy_keys_ensure_task_name: :make_sure)

        expect(Rake.application)
          .to(have_task_defined('deploy_keys:make_sure'))
      end

      it 'uses a destroy task name of destroy by default' do
        define_tasks

        rake_task = Rake::Task['deploy_keys:ensure']

        expect(rake_task.creator.destroy_task_name)
          .to(eq(:destroy))
      end

      it 'uses the provided destroy task name when supplied' do
        define_tasks(deploy_keys_destroy_task_name: :destroy_it_all)

        rake_task = Rake::Task['deploy_keys:ensure']

        expect(rake_task.creator.destroy_task_name)
          .to(eq(:destroy_it_all))
      end

      it 'uses a provision task name of provision by default' do
        define_tasks

        rake_task = Rake::Task['deploy_keys:ensure']

        expect(rake_task.creator.provision_task_name)
          .to(eq(:provision))
      end

      it 'uses the provided provision task name when supplied' do
        define_tasks(deploy_keys_provision_task_name: :provision_some_things)

        rake_task = Rake::Task['deploy_keys:ensure']

        expect(rake_task.creator.provision_task_name)
          .to(eq(:provision_some_things))
      end
    end
  end
end
