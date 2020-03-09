require 'spec_helper'
require 'octokit'

describe RakeGithub::Tasks::DeployKey::Destroy do
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

  it 'adds a destroy task in the namespace in which it is created' do
    define_task(
        repository: 'org/repo',
        access_token: 'some-token',
        title: 'some-deploy-key')

    expect(Rake::Task.task_defined?('deploy_key:destroy'))
        .to(be(true))
  end

  it 'gives the destroy task a description' do
    define_task(
        repository: 'org/repo',
        access_token: 'some-token',
        title: 'some-deploy-key')

    expect(Rake::Task['deploy_key:destroy'].full_comment)
        .to(eq('Destroys deploy key from the org/repo repository'))
  end

  it 'fails if no repository is provided' do
    define_task(
        access_token: 'some-token',
        title: 'some-deploy-key',
        public_key: File.read('spec/fixtures/ssh.public'))

    expect {
      Rake::Task['deploy_key:destroy'].invoke
    }.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no access token is provided' do
    define_task(
        repository: 'org/repo',
        title: 'some-deploy-key',
        public_key: File.read('spec/fixtures/ssh.public'))

    expect {
      Rake::Task['deploy_key:destroy'].invoke
    }.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no title is provided' do
    define_task(
        repository: 'org/repo',
        access_token: 'some-token',
        public_key: File.read('spec/fixtures/ssh.public'))

    expect {
      Rake::Task['deploy_key:destroy'].invoke
    }.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'finds and removes the deploy key from the repository' do
    repository = 'org/repo'
    access_token = 'some-token'
    matching_title = 'some-deploy-key'
    matching_id = '124fdc2a'
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
                {id: matching_id, title: matching_title},
                {id: other_id, title: other_title}
            ]))
    expect(client)
        .to(receive(:remove_deploy_key)
            .with(repository, matching_id))

    define_task(
        repository: repository,
        access_token: access_token,
        title: matching_title)

    Rake::Task['deploy_key:destroy'].invoke
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
