# frozen_string_literal: true

require 'spec_helper'
require 'octokit'
require 'sawyer'
require 'rbnacl'
require 'base64'

describe RakeGithub::Tasks::Secrets::Provision do
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

  it 'adds a provision task in the namespace in which it is created' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token'
    )

    expect(Rake.application)
      .to(have_task_defined('secrets:provision'))
  end

  it 'gives the provision task a description' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token'
    )

    expect(Rake::Task['secrets:provision'].full_comment)
      .to(eq('Provision secrets to the org/repo repository'))
  end

  it 'fails if no repository is provided' do
    define_task(
      access_token: 'some-token'
    )

    expect do
      Rake::Task['secrets:provision'].invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no access token is provided' do
    define_task(
      repository: 'org/repo'
    )

    expect do
      Rake::Task['secrets:provision'].invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'has no secrets by default' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token'
    )

    rake_task = Rake::Task['secrets:provision']
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

    rake_task = Rake::Task['secrets:provision']
    test_task = rake_task.creator

    expect(test_task.secrets).to(eq(secrets))
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'creates or updates the actions secret with a sealed value' do
    repository = 'org/repo'
    access_token = 'some-token'
    private_key = RbNaCl::PrivateKey.generate

    client = stub_github_client
    stub_actions_public_key(client, repository, 'actions-key-id', private_key)

    define_task(
      repository:,
      access_token:,
      secrets: [{ name: 'SOME_SECRET', value: 'some-value' }]
    )

    Rake::Task['secrets:provision'].invoke

    expect(Octokit::Client)
      .to(have_received(:new)
            .with(hash_including(access_token:)))
    expect(decrypted_actions_value(client, private_key, 'SOME_SECRET'))
      .to(eq('some-value'))
  end
  # rubocop:enable RSpec/MultipleExpectations

  it 'does not write to the dependabot store by default' do
    repository = 'org/repo'

    client = stub_github_client

    define_task(
      repository:,
      access_token: 'some-token',
      secrets: [{ name: 'SOME_SECRET', value: 'some-value' }]
    )

    Rake::Task['secrets:provision'].invoke

    expect(client)
      .not_to(have_received(:create_or_update_dependabot_secret))
  end

  it 'does not fetch the dependabot public key when no secret opts in' do
    client = stub_github_client

    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      secrets: [{ name: 'SOME_SECRET', value: 'some-value' }]
    )

    Rake::Task['secrets:provision'].invoke

    expect(client).not_to(have_received(:get_dependabot_public_key))
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'writes every secret to actions but only opted-in secrets to dependabot' do
    repository = 'org/repo'

    client = stub_github_client

    define_task(
      repository:,
      access_token: 'some-token',
      secrets: [
        { name: 'ACTIONS_ONLY', value: 'value-one' },
        { name: 'BOTH', value: 'value-two', dependabot: true }
      ]
    )

    Rake::Task['secrets:provision'].invoke

    expect(client)
      .to(have_received(:create_or_update_actions_secret)
            .with(repository, 'ACTIONS_ONLY', anything))
    expect(client)
      .to(have_received(:create_or_update_actions_secret)
            .with(repository, 'BOTH', anything))
    expect(client)
      .to(have_received(:create_or_update_dependabot_secret)
            .with(repository, 'BOTH', anything))
    expect(client)
      .not_to(have_received(:create_or_update_dependabot_secret)
                .with(repository, 'ACTIONS_ONLY', anything))
  end
  # rubocop:enable RSpec/MultipleExpectations

  it 'creates or updates the dependabot secret with a sealed value' do
    repository = 'org/repo'
    access_token = 'some-token'
    private_key = RbNaCl::PrivateKey.generate

    client = stub_github_client
    stub_dependabot_public_key(
      client, repository, 'dependabot-key-id', private_key
    )

    define_task(
      repository:,
      access_token:,
      secrets: [{ name: 'SOME_SECRET', value: 'some-value', dependabot: true }]
    )

    Rake::Task['secrets:provision'].invoke

    expect(decrypted_dependabot_value(client, private_key, 'SOME_SECRET'))
      .to(eq('some-value'))
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'seals each store value against that store own public key' do
    repository = 'org/repo'
    actions_private_key = RbNaCl::PrivateKey.generate
    dependabot_private_key = RbNaCl::PrivateKey.generate

    client = stub_github_client
    stub_actions_public_key(
      client, repository, 'actions-key-id', actions_private_key
    )
    stub_dependabot_public_key(
      client, repository, 'dependabot-key-id', dependabot_private_key
    )

    define_task(
      repository:,
      access_token: 'some-token',
      secrets: [{ name: 'SOME_SECRET', value: 'some-value', dependabot: true }]
    )

    Rake::Task['secrets:provision'].invoke

    expect(
      decrypted_actions_value(client, actions_private_key, 'SOME_SECRET')
    ).to(eq('some-value'))
    expect(
      decrypted_dependabot_value(
        client, dependabot_private_key, 'SOME_SECRET'
      )
    ).to(eq('some-value'))
  end
  # rubocop:enable RSpec/MultipleExpectations

  it 'passes the fetched key id to the actions secret' do
    repository = 'org/repo'
    private_key = RbNaCl::PrivateKey.generate

    client = stub_github_client
    stub_actions_public_key(client, repository, 'actions-key-id', private_key)

    define_task(
      repository:,
      access_token: 'some-token',
      secrets: [{ name: 'SOME_SECRET', value: 'some-value' }]
    )

    Rake::Task['secrets:provision'].invoke

    expect(client)
      .to(have_received(:create_or_update_actions_secret)
            .with(repository, 'SOME_SECRET',
                  hash_including(key_id: 'actions-key-id')))
  end

  it 'passes the fetched key id to the dependabot secret' do
    repository = 'org/repo'
    private_key = RbNaCl::PrivateKey.generate

    client = stub_github_client
    stub_dependabot_public_key(
      client, repository, 'dependabot-key-id', private_key
    )

    define_task(
      repository:,
      access_token: 'some-token',
      secrets: [{ name: 'SOME_SECRET', value: 'some-value', dependabot: true }]
    )

    Rake::Task['secrets:provision'].invoke

    expect(client)
      .to(have_received(:create_or_update_dependabot_secret)
            .with(repository, 'SOME_SECRET',
                  hash_including(key_id: 'dependabot-key-id')))
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'fetches each public key once per run rather than per secret' do
    repository = 'org/repo'
    private_key = RbNaCl::PrivateKey.generate

    client = stub_github_client
    stub_actions_public_key(client, repository, 'actions-key-id', private_key)
    stub_dependabot_public_key(
      client, repository, 'dependabot-key-id', private_key
    )

    define_task(
      repository:,
      access_token: 'some-token',
      secrets: [
        { name: 'SECRET_ONE', value: 'value-one', dependabot: true },
        { name: 'SECRET_TWO', value: 'value-two', dependabot: true }
      ]
    )

    Rake::Task['secrets:provision'].invoke

    expect(client).to(have_received(:get_actions_public_key).once)
    expect(client).to(have_received(:get_dependabot_public_key).once)
  end
  # rubocop:enable RSpec/MultipleExpectations

  def public_key_resource(key_id, private_key)
    agent = Sawyer::Agent.new('https://api.github.com')
    Sawyer::Resource.new(
      agent,
      {
        key_id:,
        key: Base64.strict_encode64(private_key.public_key.to_bytes)
      }
    )
  end

  def stub_actions_public_key(client, repository, key_id, private_key)
    allow(client)
      .to(receive(:get_actions_public_key)
            .with(repository)
            .and_return(public_key_resource(key_id, private_key)))
  end

  def stub_dependabot_public_key(client, repository, key_id, private_key)
    allow(client)
      .to(receive(:get_dependabot_public_key)
            .with(repository)
            .and_return(public_key_resource(key_id, private_key)))
  end

  def captured_encrypted_value(client, method, name)
    encrypted_value = nil
    expect(client)
      .to(have_received(method) do |_repo, secret_name, opts|
        encrypted_value = opts[:encrypted_value] if secret_name == name
      end)
    encrypted_value
  end

  def decrypt(private_key, encrypted_value)
    box = RbNaCl::Boxes::Sealed.from_private_key(private_key)
    box.decrypt(Base64.decode64(encrypted_value))
  end

  def decrypted_actions_value(client, private_key, name)
    encrypted_value = captured_encrypted_value(
      client, :create_or_update_actions_secret, name
    )
    decrypt(private_key, encrypted_value)
  end

  def decrypted_dependabot_value(client, private_key, name)
    encrypted_value = captured_encrypted_value(
      client, :create_or_update_dependabot_secret, name
    )
    decrypt(private_key, encrypted_value)
  end

  def stub_output
    %i[print puts].each do |method|
      allow($stdout).to(receive(method))
      allow($stderr).to(receive(method))
    end
  end

  def stub_github_client
    client = instance_double(Octokit::Client, default_client_stubs)
    allow(Octokit::Client)
      .to(receive(:new).and_return(client))
    client
  end

  def default_client_stubs
    private_key = RbNaCl::PrivateKey.generate
    {
      get_actions_public_key:
        public_key_resource('actions-key-id', private_key),
      get_dependabot_public_key:
        public_key_resource('dependabot-key-id', private_key),
      create_or_update_actions_secret: nil,
      create_or_update_dependabot_secret: nil
    }
  end
end
