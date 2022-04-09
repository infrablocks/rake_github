# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RakeGithub do
  it 'has a version number' do
    expect(RakeGithub::VERSION).not_to be_nil
  end

  describe 'define_deploy_keys_tasks' do
    context 'when instantiating RakeGithub::TaskSets::DeployKeys' do
      # rubocop:disable RSpec/MultipleExpectations
      it 'passes the provided block' do
        opts = {
          repository: 'org/repo'
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

        allow(RakeGithub::TaskSets::DeployKeys).to(receive(:define))

        described_class.define_deploy_keys_tasks(opts, &block)

        expect(RakeGithub::TaskSets::DeployKeys)
          .to(have_received(:define) do |passed_opts, &passed_block|
            expect(passed_opts).to(eq(opts))
            expect(passed_block).to(eq(block))
          end)
      end
      # rubocop:enable RSpec/MultipleExpectations
    end
  end

  describe 'define_repository_tasks' do
    context 'when instantiating RakeGithub::TaskSets::Repository' do
      # rubocop:disable RSpec/MultipleExpectations
      it 'passes the provided block' do
        opts = {
          repository: 'org/repo'
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

        allow(RakeGithub::TaskSets::Repository).to(receive(:define))

        described_class.define_repository_tasks(opts, &block)

        expect(RakeGithub::TaskSets::Repository)
          .to(have_received(:define) do |passed_opts, &passed_block|
            expect(passed_opts).to(eq(opts))
            expect(passed_block).to(eq(block))
          end)
      end
      # rubocop:enable RSpec/MultipleExpectations
    end
  end

  describe 'define_release_task' do
    context 'when instantiating RakeGithub::Tasks::Releases::Create' do
      # rubocop:disable RSpec/MultipleExpectations
      it 'passes the provided block' do
        opts = {
          repository: 'org/repo'
        }

        block = lambda do |t|
          t.access_token = 'some-token'
          t.tag_name = '0.1.0'
        end

        allow(RakeGithub::Tasks::Releases::Create).to(receive(:define))

        described_class.define_release_task(opts, &block)

        expect(RakeGithub::Tasks::Releases::Create)
          .to(have_received(:define) do |passed_opts, &passed_block|
            expect(passed_opts).to(eq(opts))
            expect(passed_block).to(eq(block))
          end)
      end
      # rubocop:enable RSpec/MultipleExpectations
    end
  end
end
