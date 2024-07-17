# frozen_string_literal: true

require 'spec_helper'
require 'octokit'

describe RakeGithub::Tasks::DeployKeys::Provision do
  include_context 'rake'

  before do
    stub_output
    stub_github_client
  end

  def define_task(opts = {}, &block)
    opts = { namespace: :deploy_keys }.merge(opts)

    namespace opts[:namespace] do
      described_class.define(opts, &block)
    end
  end

  it 'adds a provision task in the namespace in which it is created' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token'
    )

    expect(Rake.application)
      .to(have_task_defined('deploy_keys:provision'))
  end

  it 'gives the provision task a description' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token'
    )

    expect(Rake::Task['deploy_keys:provision'].full_comment)
      .to(eq('Provision deploy keys to the org/repo repository'))
  end

  it 'fails if no repository is provided' do
    define_task(
      access_token: 'some-token'
    )

    expect do
      Rake::Task['deploy_keys:provision'].invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no access token is provided' do
    define_task(
      repository: 'org/repo'
    )

    expect do
      Rake::Task['deploy_keys:provision'].invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'has no deploy keys by default' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token'
    )

    rake_task = Rake::Task['deploy_keys:provision']
    test_task = rake_task.creator

    expect(test_task.deploy_keys).to(eq([]))
  end

  it 'uses the provided deploy keys when supplied' do
    deploy_keys = [
      {
        title: 'some-deploy-key',
        public_key: File.read('spec/fixtures/1.public')
      }
    ]

    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      deploy_keys:
    )

    rake_task = Rake::Task['deploy_keys:provision']
    test_task = rake_task.creator

    expect(test_task.deploy_keys).to(eq(deploy_keys))
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'adds the deploy keys on the repository' do
    repository = 'org/repo'
    access_token = 'some-token'
    title1 = 'some-deploy-key-1'
    public_key1 = File.read('spec/fixtures/1.public')
    read_only1 = true
    title2 = 'some-deploy-key-2'
    public_key2 = File.read('spec/fixtures/2.public')

    client = stub_github_client

    allow(client).to(receive(:add_deploy_key))

    define_task(
      repository:,
      access_token:,
      deploy_keys: [
        {
          title: title1,
          public_key: public_key1,
          read_only: read_only1
        },
        {
          title: title2,
          public_key: public_key2
        }
      ]
    )

    Rake::Task['deploy_keys:provision'].invoke

    expect(Octokit::Client)
      .to(have_received(:new)
            .with(hash_including(
                    access_token:
                  )))
    expect(client)
      .to(have_received(:add_deploy_key)
            .with(repository, title1, public_key1, read_only: read_only1))
    expect(client)
      .to(have_received(:add_deploy_key)
            .with(repository, title2, public_key2, read_only: false))
  end
  # rubocop:enable RSpec/MultipleExpectations

  def stub_output
    %i[print puts].each do |method|
      allow($stdout).to(receive(method))
      allow($stderr).to(receive(method))
    end
  end

  def stub_github_client
    client = instance_double(
      Octokit::Client,
      add_deploy_key: nil
    )
    allow(Octokit::Client)
      .to(receive(:new)
            .and_return(client))
    client
  end
end
