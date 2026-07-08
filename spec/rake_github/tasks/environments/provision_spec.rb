# frozen_string_literal: true

require 'spec_helper'
require 'octokit'
require 'sawyer'

describe RakeGithub::Tasks::Environments::Provision do
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

  it 'adds a provision task in the namespace in which it is created' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token'
    )

    expect(Rake.application)
      .to(have_task_defined('environments:provision'))
  end

  it 'gives the provision task a description' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token'
    )

    expect(Rake::Task['environments:provision'].full_comment)
      .to(eq('Provision environments to the org/repo repository'))
  end

  it 'fails if no repository is provided' do
    define_task(
      access_token: 'some-token'
    )

    expect do
      Rake::Task['environments:provision'].invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no access token is provided' do
    define_task(
      repository: 'org/repo'
    )

    expect do
      Rake::Task['environments:provision'].invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'has no environments by default' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token'
    )

    rake_task = Rake::Task['environments:provision']
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

    rake_task = Rake::Task['environments:provision']
    test_task = rake_task.creator

    expect(test_task.environments).to(eq(environments))
  end

  it 'creates or updates each environment on the repository' do
    repository = 'org/repo'
    access_token = 'some-token'

    client = stub_github_client

    define_task(
      repository:,
      access_token:,
      environments: [{ name: 'release' }]
    )

    Rake::Task['environments:provision'].invoke

    expect(client)
      .to(have_received(:create_or_update_environment)
            .with(repository, 'release', anything))
  end

  it 'uses the provided access token' do
    access_token = 'some-token'

    define_task(
      repository: 'org/repo',
      access_token:,
      environments: [{ name: 'release' }]
    )

    Rake::Task['environments:provision'].invoke

    expect(Octokit::Client)
      .to(have_received(:new)
            .with(hash_including(access_token:)))
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'resolves a team reviewer to its numeric id against the owner org' do
    repository = 'infrablocks/rake_github'

    client = stub_github_client
    allow(client)
      .to(receive(:team_by_name)
            .with('infrablocks', 'maintainers')
            .and_return(team_resource(42)))

    define_task(
      repository:,
      access_token: 'some-token',
      environments: [
        { name: 'release', reviewers: [{ team: 'maintainers' }] }
      ]
    )

    Rake::Task['environments:provision'].invoke

    expect(client)
      .to(have_received(:team_by_name).with('infrablocks', 'maintainers'))
    expect(client)
      .to(have_received(:create_or_update_environment)
            .with(repository, 'release',
                  hash_including(reviewers: [{ type: 'Team', id: 42 }])))
  end
  # rubocop:enable RSpec/MultipleExpectations

  it 'resolves a user reviewer to its numeric id' do
    repository = 'infrablocks/rake_github'

    client = stub_github_client
    allow(client)
      .to(receive(:user)
            .with('someone')
            .and_return(user_resource(7)))

    define_task(
      repository:,
      access_token: 'some-token',
      environments: [
        { name: 'release', reviewers: [{ user: 'someone' }] }
      ]
    )

    Rake::Task['environments:provision'].invoke

    expect(client)
      .to(have_received(:create_or_update_environment)
            .with(repository, 'release',
                  hash_including(reviewers: [{ type: 'User', id: 7 }])))
  end

  it 'resolves a mix of team and user reviewers in order' do
    repository = 'infrablocks/rake_github'

    client = stub_github_client
    allow(client)
      .to(receive(:team_by_name)
            .with('infrablocks', 'maintainers')
            .and_return(team_resource(42)))
    allow(client)
      .to(receive(:user)
            .with('someone')
            .and_return(user_resource(7)))

    define_task(
      repository:,
      access_token: 'some-token',
      environments: [
        {
          name: 'release',
          reviewers: [{ team: 'maintainers' }, { user: 'someone' }]
        }
      ]
    )

    Rake::Task['environments:provision'].invoke

    expect(client)
      .to(have_received(:create_or_update_environment)
            .with(repository, 'release',
                  hash_including(reviewers: [
                                   { type: 'Team', id: 42 },
                                   { type: 'User', id: 7 }
                                 ])))
  end

  it 'passes through the provided optional keys when supplied' do
    repository = 'org/repo'

    client = stub_github_client

    define_task(
      repository:,
      access_token: 'some-token',
      environments: [
        {
          name: 'release',
          wait_timer: 30,
          prevent_self_review: true,
          deployment_branch_policy: {
            protected_branches: true,
            custom_branch_policies: false
          }
        }
      ]
    )

    Rake::Task['environments:provision'].invoke

    expect(client)
      .to(have_received(:create_or_update_environment)
            .with(repository, 'release',
                  hash_including(
                    wait_timer: 30,
                    prevent_self_review: true,
                    deployment_branch_policy: {
                      protected_branches: true,
                      custom_branch_policies: false
                    }
                  )))
  end

  it 'omits optional keys that are not supplied from the payload' do
    repository = 'org/repo'

    client = stub_github_client

    define_task(
      repository:,
      access_token: 'some-token',
      environments: [{ name: 'release' }]
    )

    Rake::Task['environments:provision'].invoke

    expect(client)
      .to(have_received(:create_or_update_environment)
            .with(repository, 'release', {}))
  end

  it 'retains falsy optional values such as wait_timer zero' do
    repository = 'org/repo'

    client = stub_github_client

    define_task(
      repository:,
      access_token: 'some-token',
      environments: [
        { name: 'release', wait_timer: 0, prevent_self_review: false }
      ]
    )

    Rake::Task['environments:provision'].invoke

    expect(client)
      .to(have_received(:create_or_update_environment)
            .with(repository, 'release',
                  hash_including(wait_timer: 0, prevent_self_review: false)))
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'creates or updates each of multiple environments' do
    repository = 'org/repo'

    client = stub_github_client

    define_task(
      repository:,
      access_token: 'some-token',
      environments: [
        { name: 'staging' },
        { name: 'release' }
      ]
    )

    Rake::Task['environments:provision'].invoke

    expect(client)
      .to(have_received(:create_or_update_environment)
            .with(repository, 'staging', anything))
    expect(client)
      .to(have_received(:create_or_update_environment)
            .with(repository, 'release', anything))
  end
  # rubocop:enable RSpec/MultipleExpectations

  it 'resolves each distinct team once per run' do
    client = stub_github_client
    allow(client)
      .to(receive(:team_by_name)
            .with('infrablocks', 'maintainers')
            .and_return(team_resource(42)))

    define_task(
      repository: 'infrablocks/rake_github',
      access_token: 'some-token',
      environments: [
        { name: 'staging', reviewers: [{ team: 'maintainers' }] },
        { name: 'release', reviewers: [{ team: 'maintainers' }] }
      ]
    )

    Rake::Task['environments:provision'].invoke

    expect(client).to(have_received(:team_by_name).once)
  end

  it 'resolves each distinct user once per run' do
    client = stub_github_client
    allow(client)
      .to(receive(:user)
            .with('someone')
            .and_return(user_resource(7)))

    define_task(
      repository: 'infrablocks/rake_github',
      access_token: 'some-token',
      environments: [
        { name: 'staging', reviewers: [{ user: 'someone' }] },
        { name: 'release', reviewers: [{ user: 'someone' }] }
      ]
    )

    Rake::Task['environments:provision'].invoke

    expect(client).to(have_received(:user).once)
  end

  def team_resource(id)
    agent = Sawyer::Agent.new('https://api.github.com')
    Sawyer::Resource.new(agent, { id: })
  end

  def user_resource(id)
    agent = Sawyer::Agent.new('https://api.github.com')
    Sawyer::Resource.new(agent, { id: })
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
      create_or_update_environment: nil,
      team_by_name: team_resource(1),
      user: user_resource(1)
    )
    allow(Octokit::Client)
      .to(receive(:new).and_return(client))
    client
  end
end
