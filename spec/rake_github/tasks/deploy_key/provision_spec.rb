require 'spec_helper'
require 'octokit'

describe RakeGithub::Tasks::DeployKey::Provision do
  include_context :rake

  before(:each) do
    stub_output
    stub_github_client
  end

  def define_task(opts = {}, &block)
    opts = {namespace: :deploy_key}.merge(opts)

    namespace opts[:namespace] do
      subject.define(opts, &block)
    end
  end

  it 'adds a provision task in the namespace in which it is created' do
    define_task(
        repository: 'org/repo',
        access_token: 'some-token',
        title: 'some-deploy-key',
        public_key: File.read('spec/fixtures/ssh.public'))

    expect(Rake::Task.task_defined?('deploy_key:provision'))
        .to(be(true))
  end

  it 'gives the provision task a description' do
    define_task(
        repository: 'org/repo',
        access_token: 'some-token',
        title: 'some-deploy-key',
        public_key: File.read('spec/fixtures/ssh.public'))

    expect(Rake::Task['deploy_key:provision'].full_comment)
        .to(eq('Provision deploy key to the org/repo repository'))
  end

  it 'fails if no repository is provided' do
    define_task(
        access_token: 'some-token',
        title: 'some-deploy-key',
        public_key: File.read('spec/fixtures/ssh.public'))

    expect {
      Rake::Task['deploy_key:provision'].invoke
    }.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no access token is provided' do
    define_task(
        repository: 'org/repo',
        title: 'some-deploy-key',
        public_key: File.read('spec/fixtures/ssh.public'))

    expect {
      Rake::Task['deploy_key:provision'].invoke
    }.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no title is provided' do
    define_task(
        repository: 'org/repo',
        access_token: 'some-token',
        public_key: File.read('spec/fixtures/ssh.public'))

    expect {
      Rake::Task['deploy_key:provision'].invoke
    }.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no public key is provided' do
    define_task(
        repository: 'org/repo',
        access_token: 'some-token',
        title: 'some-deploy-key')

    expect {
      Rake::Task['deploy_key:provision'].invoke
    }.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'defaults to a read/write deploy key' do
    define_task(
        repository: 'org/repo',
        access_token: 'some-token',
        title: 'some-deploy-key',
        public_key: File.read('spec/fixtures/ssh.public'))

    rake_task = Rake::Task['deploy_key:provision']
    test_task = rake_task.creator

    expect(test_task.read_only).to(be(false))
  end

  it 'adds the deploy key on the repository' do
    repository = 'org/repo'
    access_token = 'some-token'
    title = 'some-deploy-key'
    public_key = File.read('spec/fixtures/ssh.public')
    read_only = true

    client = double('Github client')

    allow(Octokit::Client)
        .to(receive(:new)
            .with(hash_including(
                access_token: access_token))
            .and_return(client))

    expect(client).to(receive(:add_deploy_key)
        .with(repository, title, public_key, read_only: read_only))

    define_task(
        repository: repository,
        access_token: access_token,
        title: title,
        public_key: public_key,
        read_only: read_only)

    Rake::Task['deploy_key:provision'].invoke
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
