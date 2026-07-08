# frozen_string_literal: true

require 'spec_helper'
require 'octokit'

describe RakeGithub::Tasks::Secrets::Destroy do
  include_context 'rake'

  before do
    stub_output
    stub_github_client
  end

  def define_task(opts = {}, &block)
    opts = { namespace: :secrets }.merge(opts)

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
      .to(have_task_defined('secrets:destroy'))
  end

  it 'gives the destroy task a description' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token'
    )

    expect(Rake::Task['secrets:destroy'].full_comment)
      .to(eq('Destroys secrets from the org/repo repository'))
  end

  it 'fails if no repository is provided' do
    define_task(
      access_token: 'some-token'
    )

    expect do
      Rake::Task['secrets:destroy'].invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no access token is provided' do
    define_task(
      repository: 'org/repo'
    )

    expect do
      Rake::Task['secrets:destroy'].invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'has no secrets by default' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token'
    )

    rake_task = Rake::Task['secrets:destroy']
    test_task = rake_task.creator

    expect(test_task.secrets).to(eq([]))
  end

  it 'uses the provided secrets when supplied' do
    secrets = [
      { name: 'SOME_SECRET', value: 'some-value' }
    ]

    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      secrets:
    )

    rake_task = Rake::Task['secrets:destroy']
    test_task = rake_task.creator

    expect(test_task.secrets).to(eq(secrets))
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'deletes each secret from both the actions and dependabot stores' do
    repository = 'org/repo'
    access_token = 'some-token'

    client = stub_github_client

    define_task(
      repository:,
      access_token:,
      secrets: [
        { name: 'SECRET_ONE', value: 'value-one' },
        { name: 'SECRET_TWO', value: 'value-two' }
      ]
    )

    Rake::Task['secrets:destroy'].invoke

    expect(Octokit::Client)
      .to(have_received(:new)
            .with(hash_including(access_token:)))
    expect(client)
      .to(have_received(:delete_actions_secret)
            .with(repository, 'SECRET_ONE'))
    expect(client)
      .to(have_received(:delete_actions_secret)
            .with(repository, 'SECRET_TWO'))
    expect(client)
      .to(have_received(:delete_dependabot_secret)
            .with(repository, 'SECRET_ONE'))
    expect(client)
      .to(have_received(:delete_dependabot_secret)
            .with(repository, 'SECRET_TWO'))
  end
  # rubocop:enable RSpec/MultipleExpectations

  it 'still deletes the dependabot secret when the actions secret is absent' do
    repository = 'org/repo'

    client = stub_github_client
    allow(client)
      .to(receive(:delete_actions_secret)
            .and_raise(Octokit::NotFound))

    define_task(
      repository:,
      access_token: 'some-token',
      secrets: [{ name: 'SOME_SECRET', value: 'some-value' }]
    )

    Rake::Task['secrets:destroy'].invoke

    expect(client)
      .to(have_received(:delete_dependabot_secret)
            .with(repository, 'SOME_SECRET'))
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'still deletes remaining secrets when an earlier secret is absent' do
    repository = 'org/repo'

    client = stub_github_client
    allow(client)
      .to(receive(:delete_actions_secret)
            .with(repository, 'SECRET_ONE')
            .and_raise(Octokit::NotFound))
    allow(client)
      .to(receive(:delete_dependabot_secret)
            .with(repository, 'SECRET_ONE')
            .and_raise(Octokit::NotFound))

    define_task(
      repository:,
      access_token: 'some-token',
      secrets: [
        { name: 'SECRET_ONE', value: 'value-one' },
        { name: 'SECRET_TWO', value: 'value-two' }
      ]
    )

    Rake::Task['secrets:destroy'].invoke

    expect(client)
      .to(have_received(:delete_actions_secret)
            .with(repository, 'SECRET_TWO'))
    expect(client)
      .to(have_received(:delete_dependabot_secret)
            .with(repository, 'SECRET_TWO'))
  end
  # rubocop:enable RSpec/MultipleExpectations

  it 'does not raise when the dependabot secret is absent' do
    repository = 'org/repo'

    client = stub_github_client
    allow(client)
      .to(receive(:delete_dependabot_secret)
            .and_raise(Octokit::NotFound))

    define_task(
      repository:,
      access_token: 'some-token',
      secrets: [{ name: 'SOME_SECRET', value: 'some-value' }]
    )

    expect do
      Rake::Task['secrets:destroy'].invoke
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
      delete_actions_secret: nil,
      delete_dependabot_secret: nil
    )
    allow(Octokit::Client)
      .to(receive(:new).and_return(client))
    client
  end
end
