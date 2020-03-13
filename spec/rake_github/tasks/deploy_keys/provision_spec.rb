require 'spec_helper'
require 'octokit'

describe RakeGithub::Tasks::DeployKeys::Provision do
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

  it 'adds a provision task in the namespace in which it is created' do
    define_task(
        repository: 'org/repo',
        access_token: 'some-token')

    expect(Rake::Task.task_defined?('deploy_keys:provision'))
        .to(be(true))
  end

  it 'gives the provision task a description' do
    define_task(
        repository: 'org/repo',
        access_token: 'some-token')

    expect(Rake::Task['deploy_keys:provision'].full_comment)
        .to(eq('Provision deploy keys to the org/repo repository'))
  end

  it 'fails if no repository is provided' do
    define_task(
        access_token: 'some-token')

    expect {
      Rake::Task['deploy_keys:provision'].invoke
    }.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no access token is provided' do
    define_task(
        repository: 'org/repo')

    expect {
      Rake::Task['deploy_keys:provision'].invoke
    }.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'has no deploy keys by default' do
    define_task(
        repository: 'org/repo',
        access_token: 'some-token')

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
        deploy_keys: deploy_keys)

    rake_task = Rake::Task['deploy_keys:provision']
    test_task = rake_task.creator

    expect(test_task.deploy_keys).to(eq(deploy_keys))
  end

  it 'adds the deploy keys on the repository' do
    repository = 'org/repo'
    access_token = 'some-token'
    title_1 = 'some-deploy-key-1'
    public_key_1 = File.read('spec/fixtures/1.public')
    read_only_1 = true
    title_2 = 'some-deploy-key-2'
    public_key_2 = File.read('spec/fixtures/2.public')

    client = double('Github client')

    allow(Octokit::Client)
        .to(receive(:new)
            .with(hash_including(
                access_token: access_token))
            .and_return(client))

    expect(client).to(receive(:add_deploy_key)
        .with(repository, title_1, public_key_1, read_only: read_only_1))
    expect(client).to(receive(:add_deploy_key)
        .with(repository, title_2, public_key_2, read_only: false))

    define_task(
        repository: repository,
        access_token: access_token,
        deploy_keys: [
            {
                title: title_1,
                public_key: public_key_1,
                read_only: read_only_1
            },
            {
                title: title_2,
                public_key: public_key_2
            }
        ])

    Rake::Task['deploy_keys:provision'].invoke
  end

  def stub_output
    [:print, :puts].each do |method|
      allow_any_instance_of(Kernel).to(receive(method))
      allow($stdout).to(receive(method))
      allow($stderr).to(receive(method))
    end
  end

  def stub_github_client
    client = double('Github client', add_deploy_key: nil)
    allow(Octokit::Client)
        .to(receive(:new).and_return(client))
  end
end
