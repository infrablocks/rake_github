require 'spec_helper'

RSpec.describe RakeGithub do
  it 'has a version number' do
    expect(RakeGithub::VERSION).not_to be nil
  end

  context 'define_deploy_key_tasks' do
    context 'when instantiating RakeGithub::TaskSets::DeployKey' do
      it 'passes the provided block' do
        opts = {
            repository: 'org/repo',
            title: 'some-deploy-key'
        }

        block = lambda do |t|
          t.access_token = 'some-token'
          t.public_key = File.read('spec/fixtures/ssh.public')
        end

        expect(RakeGithub::TaskSets::DeployKey)
            .to(receive(:define) do |passed_opts, &passed_block|
              expect(passed_opts).to(eq(opts))
              expect(passed_block).to(eq(block))
            end)

        RakeGithub.define_deploy_key_tasks(opts, &block)
      end
    end
  end
end
