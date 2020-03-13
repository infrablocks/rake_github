require 'spec_helper'

RSpec.describe RakeGithub do
  it 'has a version number' do
    expect(RakeGithub::VERSION).not_to be nil
  end

  context 'define_deploy_keys_tasks' do
    context 'when instantiating RakeGithub::TaskSets::DeployKeys' do
      it 'passes the provided block' do
        opts = {
            repository: 'org/repo',
        }

        block = lambda do |t|
          t.access_token = 'some-token'
          t.deploy_keys = [
              {
                  title: 'some-key',
                  public_key: File.read('spec/fixtures/ssh.public')
              }
          ]
        end

        expect(RakeGithub::TaskSets::DeployKeys)
            .to(receive(:define) do |passed_opts, &passed_block|
              expect(passed_opts).to(eq(opts))
              expect(passed_block).to(eq(block))
            end)

        RakeGithub.define_deploy_keys_tasks(opts, &block)
      end
    end
  end

  context 'define_repository_tasks' do
    context 'when instantiating RakeGithub::TaskSets::Repository' do
      it 'passes the provided block' do
        opts = {
            repository: 'org/repo',
        }

        block = lambda do |t|
          t.access_token = 'some-token'
          t.deploy_keys = [
              {
                  title: 'some-key',
                  public_key: File.read('spec/fixtures/ssh.public')
              }
          ]
        end

        expect(RakeGithub::TaskSets::Repository)
            .to(receive(:define) do |passed_opts, &passed_block|
              expect(passed_opts).to(eq(opts))
              expect(passed_block).to(eq(block))
            end)

        RakeGithub.define_repository_tasks(opts, &block)
      end
    end
  end
end
