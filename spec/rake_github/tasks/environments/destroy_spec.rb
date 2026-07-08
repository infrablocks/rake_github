# frozen_string_literal: true

require 'spec_helper'
require 'octokit'

describe RakeGithub::Tasks::Environments::Destroy do
  include_context 'rake'

  before do
    stub_output
    stub_github_client
  end

  def define_task(opts = {}, &block)
    opts = { namespace: :environments }.merge(opts)

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
      .to(have_task_defined('environments:destroy'))
  end

  it 'gives the destroy task a description' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token'
    )

    expect(Rake::Task['environments:destroy'].full_comment)
      .to(eq('Destroys environments from the org/repo repository'))
  end

  it 'fails if no repository is provided' do
    define_task(
      access_token: 'some-token'
    )

    expect do
      Rake::Task['environments:destroy'].invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no access token is provided' do
    define_task(
      repository: 'org/repo'
    )

    expect do
      Rake::Task['environments:destroy'].invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'has no environments by default' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token'
    )

    rake_task = Rake::Task['environments:destroy']
    test_task = rake_task.creator

    expect(test_task.environments).to(eq([]))
  end

  it 'uses the provided environments when supplied' do
    environments = [
      { name: 'release' }
    ]

    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      environments:
    )

    rake_task = Rake::Task['environments:destroy']
    test_task = rake_task.creator

    expect(test_task.environments).to(eq(environments))
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'deletes each environment from the repository' do
    repository = 'org/repo'
    access_token = 'some-token'

    client = stub_github_client

    define_task(
      repository:,
      access_token:,
      environments: [
        { name: 'staging' },
        { name: 'release' }
      ]
    )

    Rake::Task['environments:destroy'].invoke

    expect(Octokit::Client)
      .to(have_received(:new)
            .with(hash_including(access_token:)))
    expect(client)
      .to(have_received(:delete_environment)
            .with(repository, 'staging'))
    expect(client)
      .to(have_received(:delete_environment)
            .with(repository, 'release'))
  end
  # rubocop:enable RSpec/MultipleExpectations

  it 'still deletes remaining environments when one is absent' do
    repository = 'org/repo'

    client = stub_github_client
    allow(client)
      .to(receive(:delete_environment)
            .with(repository, 'staging')
            .and_raise(Octokit::NotFound))

    define_task(
      repository:,
      access_token: 'some-token',
      environments: [
        { name: 'staging' },
        { name: 'release' }
      ]
    )

    Rake::Task['environments:destroy'].invoke

    expect(client)
      .to(have_received(:delete_environment)
            .with(repository, 'release'))
  end

  it 'does not raise when the environment is absent' do
    repository = 'org/repo'

    client = stub_github_client
    allow(client)
      .to(receive(:delete_environment)
            .and_raise(Octokit::NotFound))

    define_task(
      repository:,
      access_token: 'some-token',
      environments: [{ name: 'release' }]
    )

    expect do
      Rake::Task['environments:destroy'].invoke
    end.not_to raise_error
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
      delete_environment: nil
    )
    allow(Octokit::Client)
      .to(receive(:new).and_return(client))
    client
  end
end
