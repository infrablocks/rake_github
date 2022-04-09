# frozen_string_literal: true

require 'spec_helper'
require 'octokit'

describe RakeGithub::Tasks::DeployKeys::Destroy do
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

  it 'adds a destroy task in the namespace in which it is created' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token'
    )

    expect(Rake.application)
      .to(have_task_defined('deploy_keys:destroy'))
  end

  it 'gives the destroy task a description' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token'
    )

    expect(Rake::Task['deploy_keys:destroy'].full_comment)
      .to(eq('Destroys deploy keys from the org/repo repository'))
  end

  it 'fails if no repository is provided' do
    define_task(
      access_token: 'some-token'
    )

    expect do
      Rake::Task['deploy_keys:destroy'].invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no access token is provided' do
    define_task(
      repository: 'org/repo'
    )

    expect do
      Rake::Task['deploy_keys:destroy'].invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'has no deploy keys by default' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token'
    )

    rake_task = Rake::Task['deploy_keys:destroy']
    test_task = rake_task.creator

    expect(test_task.deploy_keys).to(eq([]))
  end

  it 'uses the provided deploy keys when provided' do
    deploy_keys = [
      {
        title: 'some-deploy-key',
        public_key: File.read('spec/fixtures/1.public')
      }
    ]

    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      deploy_keys: deploy_keys
    )

    rake_task = Rake::Task['deploy_keys:destroy']
    test_task = rake_task.creator

    expect(test_task.deploy_keys).to(eq(deploy_keys))
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'finds and removes the deploy keys from the repository' do
    repository = 'org/repo'
    access_token = 'some-token'
    matching_title1 = 'some-deploy-key-1'
    matching_id1 = '124fdc2a'
    matching_title2 = 'some-deploy-key-2'
    matching_id2 = '52dabbc3'
    other_title = 'other-deploy-key'
    other_id = '50fd2abc'

    client = stub_github_client

    stub_successful_list_deploy_keys(
      client, repository,
      [
        { id: matching_id1, title: matching_title1 },
        { id: other_id, title: other_title },
        { id: matching_id2, title: matching_title2 }
      ]
    )
    stub_successful_remove_deploy_key(client, repository, matching_id1)
    stub_successful_remove_deploy_key(client, repository, matching_id2)

    define_task(
      repository: repository,
      access_token: access_token,
      deploy_keys: [
        deploy_key(matching_title1, 'spec/fixtures/1.public'),
        deploy_key(matching_title2, 'spec/fixtures/2.public')
      ]
    )

    Rake::Task['deploy_keys:destroy'].invoke

    expect(Octokit::Client)
      .to(have_received(:new)
            .with(hash_including(access_token: access_token)))
    expect(client)
      .to(have_received(:remove_deploy_key)
            .with(repository, matching_id1))
    expect(client)
      .to(have_received(:remove_deploy_key)
            .with(repository, matching_id2))
  end
  # rubocop:enable RSpec/MultipleExpectations

  def deploy_key(title, public_key_path)
    {
      title: title,
      public_key: File.read(public_key_path)
    }
  end

  def stub_output
    %i[print puts].each do |method|
      allow($stdout).to(receive(method))
      allow($stderr).to(receive(method))
    end
  end

  def stub_github_client
    client = instance_double(
      Octokit::Client,
      list_deploy_keys: nil,
      remove_deploy_key: nil
    )
    allow(Octokit::Client)
      .to(receive(:new).and_return(client))
    client
  end

  def stub_successful_list_deploy_keys(client, repository, deploy_keys)
    allow(client)
      .to(receive(:list_deploy_keys)
            .with(repository)
            .and_return(deploy_keys))
  end

  def stub_successful_remove_deploy_key(client, repository, id)
    allow(client)
      .to(receive(:remove_deploy_key)
            .with(repository, id))
  end
end
