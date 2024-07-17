# frozen_string_literal: true

require 'spec_helper'
require 'octokit'

describe RakeGithub::Tasks::Releases::Create do
  include_context 'rake'

  def define_task(opts = {}, &block)
    opts = { namespace: :releases }.merge(opts)

    namespace opts[:namespace] do
      described_class.define(opts, &block)
    end
  end

  it 'adds a create task in the namespace in which it is created' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0'
    )

    expect(Rake.application)
      .to(have_task_defined('releases:create'))
  end

  it 'gives the create task a description' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0'
    )

    expect(Rake::Task['releases:create'].full_comment)
      .to(eq('Creates a release on the org/repo repository'))
  end

  it 'fails if no repository is provided' do
    define_task(
      access_token: 'some-token',
      tag_name: '0.1.0'
    )

    expect do
      Rake::Task['releases:create'].invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no access token is provided' do
    define_task(
      repository: 'org/repo',
      tag_name: '0.1.0'
    )

    expect do
      Rake::Task['releases:create'].invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no tag name is provided' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token'
    )

    expect do
      Rake::Task['releases:create'].invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'has no target commitish by default' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0'
    )

    rake_task = Rake::Task['releases:create']
    test_task = rake_task.creator

    expect(test_task.target_commitish).to(be_nil)
  end

  it 'uses the provided target commitish when supplied' do
    target_commitish = '2fda43e'

    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0',
      target_commitish:
    )

    rake_task = Rake::Task['releases:create']
    test_task = rake_task.creator

    expect(test_task.target_commitish).to(eq(target_commitish))
  end

  it 'has no release name by default' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0'
    )

    rake_task = Rake::Task['releases:create']
    test_task = rake_task.creator

    expect(test_task.release_name).to(be_nil)
  end

  it 'uses the provided release name when supplied' do
    release_name = 'Tangerine'

    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0',
      release_name:
    )

    rake_task = Rake::Task['releases:create']
    test_task = rake_task.creator

    expect(test_task.release_name).to(eq(release_name))
  end

  it 'has no body by default' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0'
    )

    rake_task = Rake::Task['releases:create']
    test_task = rake_task.creator

    expect(test_task.body).to(be_nil)
  end

  it 'uses the provided body when supplied' do
    body = 'Finally, we\'re releasing Tangerine...'

    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0',
      body:
    )

    rake_task = Rake::Task['releases:create']
    test_task = rake_task.creator

    expect(test_task.body).to(eq(body))
  end

  it 'has draft as false by default' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0'
    )

    rake_task = Rake::Task['releases:create']
    test_task = rake_task.creator

    expect(test_task.draft).to(be(false))
  end

  it 'uses the provided value for draft when supplied' do
    draft = true

    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0',
      draft:
    )

    rake_task = Rake::Task['releases:create']
    test_task = rake_task.creator

    expect(test_task.draft).to(eq(draft))
  end

  it 'has prerelease as false by default' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0'
    )

    rake_task = Rake::Task['releases:create']
    test_task = rake_task.creator

    expect(test_task.prerelease).to(be(false))
  end

  it 'uses the provided value for prerelease when supplied' do
    prerelease = true

    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0',
      prerelease:
    )

    rake_task = Rake::Task['releases:create']
    test_task = rake_task.creator

    expect(test_task.prerelease).to(eq(prerelease))
  end

  it 'has no discussion category name by default' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0'
    )

    rake_task = Rake::Task['releases:create']
    test_task = rake_task.creator

    expect(test_task.discussion_category_name).to(be_nil)
  end

  it 'uses the provided discussion category name when supplied' do
    discussion_category_name = 'Release 1.0'

    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0',
      discussion_category_name:
    )

    rake_task = Rake::Task['releases:create']
    test_task = rake_task.creator

    expect(test_task.discussion_category_name)
      .to(eq(discussion_category_name))
  end

  it 'has no assets by default' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0'
    )

    rake_task = Rake::Task['releases:create']
    test_task = rake_task.creator

    expect(test_task.assets).to(eq([]))
  end

  it 'uses the provided assets when supplied' do
    assets = [
      'path/to/file1.zip',
      {
        path: 'path/to/file2.zip',
        name: 'some-file.zip',
        label: 'the file'
      }
    ]

    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0',
      assets:
    )

    rake_task = Rake::Task['releases:create']
    test_task = rake_task.creator

    expect(test_task.assets).to(eq(assets))
  end

  it 'uses the provided access token when communicating with Github' do
    stub_side_effects

    repository = 'org/repo'
    access_token = 'some-token'
    tag_name = '0.1.0-rc.1'
    target_commitish = 'a34de5b'
    release_name = 'Geronimo'
    body = 'The long awaited Geronimo release...'
    draft = true
    prerelease = true
    discussion_category_name = 'Prerelease 0.1.0-rc.1'
    assets = ['path/to/the/file.zip']

    release_url = 'https://api.github.com/repos/org/repo/releases/1'

    client = stub_github_client

    stub_successful_create_release_request(client, release_url)
    stub_successful_upload_asset_request(client)

    define_task(
      repository:,
      access_token:,
      tag_name:,
      target_commitish:,
      release_name:,
      body:,
      draft:,
      prerelease:,
      discussion_category_name:,
      assets:
    )

    Rake::Task['releases:create'].invoke

    expect(Octokit::Client)
      .to(have_received(:new)
            .with(hash_including(access_token:)))
  end

  it 'creates the release on the repository' do
    stub_side_effects

    repository = 'org/repo'
    access_token = 'some-token'
    tag_name = '0.1.0-rc.1'
    target_commitish = 'a34de5b'
    release_name = 'Geronimo'
    body = 'The long awaited Geronimo release...'
    draft = true
    prerelease = true
    discussion_category_name = 'Prerelease 0.1.0-rc.1'
    assets = ['path/to/the/file.zip']

    release_url = 'https://api.github.com/repos/org/repo/releases/1'

    client = stub_github_client

    stub_successful_create_release_request(client, release_url)
    stub_successful_upload_asset_request(client)

    define_task(
      repository:,
      access_token:,
      tag_name:,
      target_commitish:,
      release_name:,
      body:,
      draft:,
      prerelease:,
      discussion_category_name:,
      assets:
    )

    Rake::Task['releases:create'].invoke

    expect(client)
      .to(have_received(:create_release)
            .with(repository, tag_name,
                  target_commitish:,
                  release_name:,
                  body:,
                  draft:,
                  prerelease:,
                  discussion_category_name:))
  end

  it 'logs that the release is being created for a release with no name' do
    repository = 'org/repo'
    access_token = 'some-token'
    tag_name = '0.1.0-rc.1'

    assets = []

    release_url = 'https://api.github.com/repos/org/repo/releases/1'

    client = stub_github_client

    stub_successful_create_release_request(client, release_url)
    stub_successful_upload_asset_request(client)

    define_task(
      repository:,
      access_token:,
      tag_name:,
      assets:
    )

    expected_log_message =
      'Creating release ' \
      "with tag '#{tag_name}' " \
      "on '#{repository}' repository...\n"

    expect do
      Rake::Task['releases:create'].invoke
    end.to(output(expected_log_message).to_stdout)
  end

  it 'logs that the release is being created for a release with a name' do
    repository = 'org/repo'
    access_token = 'some-token'
    tag_name = '0.1.0-rc.1'
    release_name = 'Geronimo'

    assets = []

    release_url = 'https://api.github.com/repos/org/repo/releases/1'

    client = stub_github_client

    stub_successful_create_release_request(client, release_url)
    stub_successful_upload_asset_request(client)

    define_task(
      repository:,
      access_token:,
      tag_name:,
      release_name:,
      assets:
    )

    expected_log_message =
      "Creating release '#{release_name}' " \
      "with tag '#{tag_name}' " \
      "on '#{repository}' repository...\n"

    expect do
      Rake::Task['releases:create'].invoke
    end.to(output(expected_log_message).to_stdout)
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'creates a release that has no assets' do
    stub_side_effects

    repository = 'org/repo'
    access_token = 'some-token'
    tag_name = '0.1.0-rc.1'
    assets = []

    release_url = 'https://api.github.com/repos/org/repo/releases/1'

    client = stub_github_client

    stub_successful_create_release_request(client, release_url)
    stub_successful_upload_asset_request(client)

    define_task(
      repository:,
      access_token:,
      tag_name:,
      assets:
    )

    Rake::Task['releases:create'].invoke

    expect(client)
      .to(have_received(:create_release)
            .with(repository, tag_name, { draft: false, prerelease: false }))
    expect(client)
      .not_to(have_received(:upload_asset))
  end
  # rubocop:enable RSpec/MultipleExpectations

  it 'uploads single asset' do
    stub_side_effects

    repository = 'org/repo'
    access_token = 'some-token'
    tag_name = '0.1.0-rc.1'
    asset_1_path = 'path/to/the/file.zip'
    assets = [asset_1_path]

    release_url = 'https://api.github.com/repos/org/repo/releases/1'

    client = stub_github_client

    stub_successful_create_release_request(client, release_url)
    stub_successful_upload_asset_request(client)

    define_task(
      repository:,
      access_token:,
      tag_name:,
      assets:
    )

    Rake::Task['releases:create'].invoke

    expect(client)
      .to(have_received(:upload_asset)
            .with(release_url, asset_1_path))
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'uploads many assets' do
    stub_side_effects

    repository = 'org/repo'
    access_token = 'some-token'
    tag_name = '0.1.0-rc.1'
    asset_1_path = 'path/to/the/file1.zip'
    asset_2_path = 'path/to/the/file2.zip'
    assets = [asset_1_path, asset_2_path]

    release_url = 'https://api.github.com/repos/org/repo/releases/1'

    client = stub_github_client

    stub_successful_create_release_request(client, release_url)
    stub_successful_upload_asset_request(client)

    define_task(
      repository:,
      access_token:,
      tag_name:,
      assets:
    )

    Rake::Task['releases:create'].invoke

    expect(client)
      .to(have_received(:upload_asset)
            .with(release_url, asset_1_path))
    expect(client)
      .to(have_received(:upload_asset)
            .with(release_url, asset_2_path))
  end
  # rubocop:enable RSpec/MultipleExpectations

  it 'uploads asset with specific name' do
    stub_side_effects

    repository = 'org/repo'
    access_token = 'some-token'
    tag_name = '0.1.0-rc.1'
    asset_name = 'someName'
    asset_1_path = 'path/to/the/file.zip'
    assets = [{
      path: asset_1_path,
      name: asset_name
    }]

    release_url = 'https://api.github.com/repos/org/repo/releases/1'

    client = stub_github_client

    stub_successful_create_release_request(client, release_url)
    stub_successful_upload_asset_request(client)

    define_task(
      repository:,
      access_token:,
      tag_name:,
      assets:
    )

    Rake::Task['releases:create'].invoke

    expect(client)
      .to(have_received(:upload_asset)
            .with(release_url, asset_1_path, { name: asset_name }))
  end

  it 'logs when uploading each asset' do
    repository = 'org/repo'
    access_token = 'some-token'
    tag_name = '0.1.0-rc.1'
    asset_1_path = 'path/to/the/file1.zip'
    asset_2_path = 'path/to/the/file2.zip'
    asset_2_name = 'important.zip'
    asset_2_definition = { path: asset_2_path, name: asset_2_name }
    assets = [asset_1_path, asset_2_definition]

    release_url = 'https://api.github.com/repos/org/repo/releases/1'

    client = stub_github_client

    stub_successful_create_release_request(client, release_url)
    stub_successful_upload_asset_request(client)

    define_task(
      repository:,
      access_token:,
      tag_name:,
      assets:
    )

    expected_log_message1 =
      "Uploading asset '#{asset_1_path}' " \
      'to release ' \
      "with tag '#{tag_name}'..."
    expected_log_message2 =
      "Uploading asset '#{asset_2_path}' " \
      "with name '#{asset_2_name}' " \
      'to release ' \
      "with tag '#{tag_name}'..."

    expect do
      Rake::Task['releases:create'].invoke
    end.to(
      output(/#{expected_log_message1}\n#{expected_log_message2}/m)
        .to_stdout
    )
  end

  def stub_side_effects
    stub_output
  end

  def stub_output
    %i[print puts].each do |method|
      allow($stdout).to(receive(method))
      allow($stderr).to(receive(method))
    end
  end

  def stub_github_client
    client = instance_double(Octokit::Client)
    allow(Octokit::Client)
      .to(receive(:new)
            .and_return(client))
    client
  end

  def stub_successful_create_release_request(client, release_url)
    agent = Sawyer::Agent.new('http://localhost')
    allow(client)
      .to(receive(:create_release)
            .and_return(
              Sawyer::Resource.new(agent, { url: release_url })
            ))
  end

  def stub_successful_upload_asset_request(client)
    allow(client)
      .to(receive(:upload_asset))
  end
end
