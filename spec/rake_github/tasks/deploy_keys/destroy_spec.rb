require 'spec_helper'
require 'octokit'

describe RakeGithub::Tasks::DeployKeys::Destroy do
  include_context :rake

  before(:each) do
    stub_output
    stub_github_client
  end

  def define_task(opts = {}, &block)
    opts = {namespace: :deploy_keys}.merge(opts)

    namespace opts[:namespace] do
      subject.define(opts, &block)
    end
  end

  it 'adds a destroy task in the namespace in which it is created' do
    define_task(
        repository: 'org/repo',
        access_token: 'some-token')

    expect(Rake::Task.task_defined?('deploy_keys:destroy'))
        .to(be(true))
  end

  it 'gives the destroy task a description' do
    define_task(
        repository: 'org/repo',
        access_token: 'some-token')

    expect(Rake::Task['deploy_keys:destroy'].full_comment)
        .to(eq('Destroys deploy keys from the org/repo repository'))
  end

  it 'fails if no repository is provided' do
    define_task(
        access_token: 'some-token')

    expect {
      Rake::Task['deploy_keys:destroy'].invoke
    }.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no access token is provided' do
    define_task(
        repository: 'org/repo')

    expect {
      Rake::Task['deploy_keys:destroy'].invoke
    }.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'has no deploy keys by default' do
    define_task(
        repository: 'org/repo',
        access_token: 'some-token')

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
        deploy_keys: deploy_keys)

    rake_task = Rake::Task['deploy_keys:destroy']
    test_task = rake_task.creator

    expect(test_task.deploy_keys).to(eq(deploy_keys))
  end

  it 'finds and removes the deploy keys from the repository' do
    repository = 'org/repo'
    access_token = 'some-token'
    matching_title_1 = 'some-deploy-key-1'
    matching_id_1 = '124fdc2a'
    matching_title_2 = 'some-deploy-key-2'
    matching_id_2 = '52dabbc3'
    other_title = 'other-deploy-key'
    other_id = '50fd2abc'

    client = double('Github client')

    allow(Octokit::Client)
        .to(receive(:new)
            .with(hash_including(
                access_token: access_token))
            .and_return(client))

    allow(client)
        .to(receive(:list_deploy_keys)
            .with(repository)
            .and_return([
                {id: matching_id_1, title: matching_title_1},
                {id: other_id, title: other_title},
                {id: matching_id_2, title: matching_title_2}
            ]))
    expect(client)
        .to(receive(:remove_deploy_key)
            .with(repository, matching_id_1))
    expect(client)
        .to(receive(:remove_deploy_key)
            .with(repository, matching_id_2))

    define_task(
        repository: repository,
        access_token: access_token,
        deploy_keys: [
            {
                title: matching_title_1,
                public_key: File.read('spec/fixtures/1.public')
            },
            {
                title: matching_title_2,
                public_key: File.read('spec/fixtures/2.public')
            }
        ])

    Rake::Task['deploy_keys:destroy'].invoke
  end

  def stub_output
    [:print, :puts].each do |method|
      allow_any_instance_of(Kernel).to(receive(method))
      allow($stdout).to(receive(method))
      allow($stderr).to(receive(method))
    end
  end

  def stub_github_client
    client = double('Github client',
        list_deploy_keys: nil,
        remove_deploy_key: nil)
    allow(Octokit::Client)
        .to(receive(:new).and_return(client))
  end
end
