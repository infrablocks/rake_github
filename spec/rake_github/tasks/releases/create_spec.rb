require 'spec_helper'
require 'octokit'

describe RakeGithub::Tasks::Releases::Create do
  include_context :rake

  def define_task(opts = {}, &block)
    opts = { namespace: :releases }.merge(opts)

    namespace opts[:namespace] do
      subject.define(opts, &block)
    end
  end

  it 'adds a create task in the namespace in which it is created' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0')

    expect(Rake::Task.task_defined?('releases:create'))
      .to(be(true))
  end

  it 'gives the create task a description' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0')

    expect(Rake::Task['releases:create'].full_comment)
      .to(eq('Creates a release on the org/repo repository'))
  end

  it 'fails if no repository is provided' do
    define_task(
      access_token: 'some-token',
      tag_name: '0.1.0')

    expect {
      Rake::Task['releases:create'].invoke
    }.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no access token is provided' do
    define_task(
      repository: 'org/repo',
      tag_name: '0.1.0')

    expect {
      Rake::Task['releases:create'].invoke
    }.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no tag name is provided' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token')

    expect {
      Rake::Task['releases:create'].invoke
    }.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'has no target commitish by default' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0')

    rake_task = Rake::Task['releases:create']
    test_task = rake_task.creator

    expect(test_task.target_commitish).to(eq(nil))
  end

  it 'uses the provided target commitish when supplied' do
    target_commitish = '2fda43e'

    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0',
      target_commitish: target_commitish)

    rake_task = Rake::Task['releases:create']
    test_task = rake_task.creator

    expect(test_task.target_commitish).to(eq(target_commitish))
  end

  it 'has no release name by default' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0')

    rake_task = Rake::Task['releases:create']
    test_task = rake_task.creator

    expect(test_task.release_name).to(eq(nil))
  end

  it 'uses the provided release name when supplied' do
    release_name = 'Tangerine'

    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0',
      release_name: release_name)

    rake_task = Rake::Task['releases:create']
    test_task = rake_task.creator

    expect(test_task.release_name).to(eq(release_name))
  end

  it 'has no body by default' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0')

    rake_task = Rake::Task['releases:create']
    test_task = rake_task.creator

    expect(test_task.body).to(eq(nil))
  end

  it 'uses the provided body when supplied' do
    body = 'Finally, we\'re releasing Tangerine...'

    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0',
      body: body)

    rake_task = Rake::Task['releases:create']
    test_task = rake_task.creator

    expect(test_task.body).to(eq(body))
  end

  it 'has draft as false by default' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0')

    rake_task = Rake::Task['releases:create']
    test_task = rake_task.creator

    expect(test_task.draft).to(eq(false))
  end

  it 'uses the provided value for draft when supplied' do
    draft = true

    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0',
      draft: draft)

    rake_task = Rake::Task['releases:create']
    test_task = rake_task.creator

    expect(test_task.draft).to(eq(draft))
  end

  it 'has prerelease as false by default' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0')

    rake_task = Rake::Task['releases:create']
    test_task = rake_task.creator

    expect(test_task.prerelease).to(eq(false))
  end

  it 'uses the provided value for prerelease when supplied' do
    prerelease = true

    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0',
      prerelease: prerelease)

    rake_task = Rake::Task['releases:create']
    test_task = rake_task.creator

    expect(test_task.prerelease).to(eq(prerelease))
  end

  it 'has no discussion category name by default' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0')

    rake_task = Rake::Task['releases:create']
    test_task = rake_task.creator

    expect(test_task.discussion_category_name).to(eq(nil))
  end

  it 'uses the provided discussion category name when supplied' do
    discussion_category_name = 'Release 1.0'

    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0',
      discussion_category_name: discussion_category_name)

    rake_task = Rake::Task['releases:create']
    test_task = rake_task.creator

    expect(test_task.discussion_category_name)
      .to(eq(discussion_category_name))
  end

  it 'has no assets by default' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0')

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
      assets: assets)

    rake_task = Rake::Task['releases:create']
    test_task = rake_task.creator

    expect(test_task.assets).to(eq(assets))
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

    agent = Sawyer::Agent.new('http://localhost')
    client = double('Github client')

    allow(Octokit::Client)
      .to(receive(:new)
            .with(hash_including(
                    access_token: access_token))
            .and_return(client))

    allow(client)
      .to(receive(:create_release)
            .and_return(
              Sawyer::Resource.new(agent, { url: release_url })))
    allow(client)
      .to(receive(:upload_asset))

    define_task(
      repository: repository,
      access_token: access_token,
      tag_name: tag_name,
      target_commitish: target_commitish,
      release_name: release_name,
      body: body,
      draft: draft,
      prerelease: prerelease,
      discussion_category_name: discussion_category_name,
      assets: assets)

    Rake::Task['releases:create'].invoke

    expect(client)
      .to(have_received(:create_release)
            .with(repository, tag_name,
                  target_commitish: target_commitish,
                  release_name: release_name,
                  body: body,
                  draft: draft,
                  prerelease: prerelease,
                  discussion_category_name: discussion_category_name))
  end

  it 'logs that the release is being created for a release with no name' do
    repository = 'org/repo'
    access_token = 'some-token'
    tag_name = '0.1.0-rc.1'

    assets = []

    release_url = 'https://api.github.com/repos/org/repo/releases/1'

    agent = Sawyer::Agent.new('http://localhost')
    client = double('Github client')

    allow(Octokit::Client)
      .to(receive(:new)
            .with(hash_including(
                    access_token: access_token))
            .and_return(client))

    allow(client)
      .to(receive(:create_release)
            .and_return(
              Sawyer::Resource.new(agent, { url: release_url })))
    allow(client)
      .to(receive(:upload_asset))

    define_task(
      repository: repository,
      access_token: access_token,
      tag_name: tag_name,
      assets: assets)

    expect do
      Rake::Task['releases:create'].invoke
    end.to(output("Creating release with tag '#{tag_name}' on '#{repository}' repository...\n").to_stdout)
  end

  it 'logs that the release is being created for a release with a name' do
    repository = 'org/repo'
    access_token = 'some-token'
    tag_name = '0.1.0-rc.1'
    release_name = 'Geronimo'

    assets = []

    release_url = 'https://api.github.com/repos/org/repo/releases/1'

    agent = Sawyer::Agent.new('http://localhost')
    client = double('Github client')

    allow(Octokit::Client)
      .to(receive(:new)
            .with(hash_including(
                    access_token: access_token))
            .and_return(client))

    allow(client)
      .to(receive(:create_release)
            .and_return(
              Sawyer::Resource.new(agent, { url: release_url })))
    allow(client)
      .to(receive(:upload_asset))

    define_task(
      repository: repository,
      access_token: access_token,
      tag_name: tag_name,
      release_name: release_name,
      assets: assets)

    expect do
      Rake::Task['releases:create'].invoke
    end.to(output("Creating release '#{release_name}' with tag '#{tag_name}' on '#{repository}' repository...\n").to_stdout)
  end

  it 'creates a release that has no assets' do
    stub_side_effects

    repository = 'org/repo'
    access_token = 'some-token'
    tag_name = '0.1.0-rc.1'
    assets = []

    release_url = 'https://api.github.com/repos/org/repo/releases/1'

    agent = Sawyer::Agent.new('http://localhost')
    client = double('Github client')

    allow(Octokit::Client)
      .to(receive(:new)
            .with(hash_including(
                    access_token: access_token))
            .and_return(client))

    allow(client)
      .to(receive(:create_release)
            .with(repository, tag_name, anything)
            .and_return(
              Sawyer::Resource.new(agent, { url: release_url })))
    allow(client)
      .to(receive(:upload_asset))

    define_task(
      repository: repository,
      access_token: access_token,
      tag_name: tag_name,
      assets: assets)

    Rake::Task['releases:create'].invoke

    expect(client)
      .to(have_received(:create_release)
            .with(repository, tag_name, anything))
    expect(client)
      .not_to(have_received(:upload_asset))
  end

  it 'uploads single asset' do
    stub_side_effects

    repository = 'org/repo'
    access_token = 'some-token'
    tag_name = '0.1.0-rc.1'
    asset_1_path = 'path/to/the/file.zip'
    assets = [asset_1_path]

    release_url = 'https://api.github.com/repos/org/repo/releases/1'

    agent = Sawyer::Agent.new('http://localhost')
    client = double('Github client')

    allow(Octokit::Client)
      .to(receive(:new)
            .with(hash_including(
                    access_token: access_token))
            .and_return(client))

    allow(client)
      .to(receive(:create_release)
            .with(repository, tag_name, anything)
            .and_return(
              Sawyer::Resource.new(agent, { url: release_url })))
    allow(client)
      .to(receive(:upload_asset))

    define_task(
      repository: repository,
      access_token: access_token,
      tag_name: tag_name,
      assets: assets)

    Rake::Task['releases:create'].invoke

    expect(client)
      .to(have_received(:upload_asset)
            .with(release_url, asset_1_path))
  end

  it 'uploads many assets' do
    stub_side_effects

    repository = 'org/repo'
    access_token = 'some-token'
    tag_name = '0.1.0-rc.1'
    asset_1_path = 'path/to/the/file1.zip'
    asset_2_path = 'path/to/the/file2.zip'
    assets = [asset_1_path, asset_2_path]

    release_url = 'https://api.github.com/repos/org/repo/releases/1'

    agent = Sawyer::Agent.new('http://localhost')
    client = double('Github client')

    allow(Octokit::Client)
      .to(receive(:new)
            .with(hash_including(
                    access_token: access_token))
            .and_return(client))

    allow(client)
      .to(receive(:create_release)
            .with(repository, tag_name, anything)
            .and_return(
              Sawyer::Resource.new(agent, { url: release_url })))
    allow(client)
      .to(receive(:upload_asset))

    define_task(
      repository: repository,
      access_token: access_token,
      tag_name: tag_name,
      assets: assets)

    Rake::Task['releases:create'].invoke

    expect(client)
      .to(have_received(:upload_asset)
            .with(release_url, asset_1_path))
    expect(client)
      .to(have_received(:upload_asset)
            .with(release_url, asset_2_path))
  end

  it 'uploads asset with specific name' do
    stub_side_effects

    repository = 'org/repo'
    access_token = 'some-token'
    tag_name = '0.1.0-rc.1'
    asset_name = "someName"
    asset_1_path = 'path/to/the/file.zip'
    assets = [{
                path: asset_1_path,
                name: asset_name
              }]

    release_url = 'https://api.github.com/repos/org/repo/releases/1'

    agent = Sawyer::Agent.new('http://localhost')
    client = double('Github client')

    allow(Octokit::Client)
      .to(receive(:new)
            .with(hash_including(
                    access_token: access_token))
            .and_return(client))

    allow(client)
      .to(receive(:create_release)
            .with(repository, tag_name, anything)
            .and_return(
              Sawyer::Resource.new(agent, { url: release_url })))
    allow(client)
      .to(receive(:upload_asset))

    define_task(
      repository: repository,
      access_token: access_token,
      tag_name: tag_name,
      assets: assets)

    Rake::Task['releases:create'].invoke

    expect(client)
      .to(have_received(:upload_asset)
            .with(release_url, asset_1_path, { name: asset_name}))
  end

  it 'logs when uploading each asset' do
    repository = 'org/repo'
    access_token = 'some-token'
    tag_name = '0.1.0-rc.1'
    asset_1_path = 'path/to/the/file1.zip'
    asset_2_path = 'path/to/the/file2.zip'
    asset_2_name = 'important.zip'
    asset_2_definition = {path: asset_2_path, name: asset_2_name}
    assets = [asset_1_path, asset_2_definition]

    release_url = 'https://api.github.com/repos/org/repo/releases/1'

    agent = Sawyer::Agent.new('http://localhost')
    client = double('Github client')

    allow(Octokit::Client)
      .to(receive(:new)
            .with(hash_including(
                    access_token: access_token))
            .and_return(client))

    allow(client)
      .to(receive(:create_release)
            .with(repository, tag_name, anything)
            .and_return(
              Sawyer::Resource.new(agent, { url: release_url })))
    allow(client)
      .to(receive(:upload_asset))

    define_task(
      repository: repository,
      access_token: access_token,
      tag_name: tag_name,
      assets: assets)

    expect do
      Rake::Task['releases:create'].invoke
    end.to(output(/Uploading asset '#{asset_1_path}' to release with tag '#{tag_name}'\.\.\..*Uploading asset '#{asset_2_path}' with name '#{asset_2_name}' to release with tag '#{tag_name}'\.\.\./m).to_stdout)
  end

  def stub_side_effects
    stub_output
  end

  def stub_output
    [:print, :puts].each do |method|
      allow_any_instance_of(Kernel).to(receive(method))
      allow($stdout).to(receive(method))
      allow($stderr).to(receive(method))
    end
  end
end