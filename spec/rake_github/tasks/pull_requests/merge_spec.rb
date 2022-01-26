require 'spec_helper'
require 'octokit'

describe RakeGithub::Tasks::PullRequests::Merge do
  include_context :rake

  def define_task(opts = {}, &block)
    opts = { namespace: :pull_requests }.merge(opts)

    namespace opts[:namespace] do
      subject.define(opts, &block)
    end
  end

  it 'adds a merge task in the namespace in which it is created' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0'
    )

    expect(Rake::Task.task_defined?('pull_requests:merge'))
      .to(be(true))
  end

  it 'gives the merge task a description' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0'
    )

    expect(Rake::Task['pull_requests:merge'].full_comment)
      .to(eq('Merges pull request on the specified branch in the org/repo repository'))
  end

  it 'fails if no repository is provided' do
    define_task(
      argument_names: [:branch_name]
    ) do |t, args|
      t.access_token = 'some-token'
      t.branch_name = args.branch_name
    end

    expect do
      Rake::Task['pull_requests:merge'].invoke('branch_name')
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no access token is provided' do
    define_task(
      argument_names: [:branch_name]
    ) do |t, args|
      t.repository = 'org/repo'
      t.branch_name = args.branch_name
    end

    expect {
      Rake::Task['pull_requests:merge'].invoke('branch_name')
    }.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no branch_name is provided' do
    define_task(
      argument_names: [:branch_name]
    ) do |t, args|
      t.repository = 'org/repo'
      t.access_token = 'some-token'
      t.branch_name = args.branch_name
    end

    expect {
      Rake::Task['pull_requests:merge'].invoke
    }.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'merges pull request associated with given branch name' do
    repository = 'org/repo'
    access_token = 'some-token'
    github_client = setup_mocks(repository, access_token)

    define_task(
      argument_names: [:branch_name]
    ) do |t, args|
      t.repository = repository
      t.access_token = access_token
      t.branch_name = args.branch_name
    end

    Rake::Task['pull_requests:merge'].invoke('mergeable_branch')

    expect(github_client)
      .to(have_received(:merge_pull_request)
            .with(repository, 1, ''))
  end

  it 'allows custom PR merge commit message' do
    repository = 'org/repo'
    access_token = 'some-token'
    commit_message = 'merge PR #1'
    github_client = setup_mocks(repository, access_token)

    define_task(
      argument_names: [:branch_name]
    ) do |t, args|
      t.repository = repository
      t.access_token = access_token
      t.branch_name = args.branch_name
      t.commit_message = commit_message
    end

    Rake::Task['pull_requests:merge'].invoke('mergeable_branch')

    expect(github_client)
      .to(have_received(:merge_pull_request)
            .with(repository, 1, commit_message))
  end

  it 'allows customisation of commit message via placeholder' do
    repository = 'org/repo'
    access_token = 'some-token'
    commit_message = '%s [skip ci]'
    github_client = setup_mocks(repository, access_token)

    define_task(
      argument_names: [:branch_name]
    ) do |t, args|
      t.repository = repository
      t.access_token = access_token
      t.branch_name = args.branch_name
      t.commit_message = commit_message
    end

    Rake::Task['pull_requests:merge'].invoke('mergeable_branch')

    expect(github_client)
      .to(have_received(:merge_pull_request)
            .with(repository, 1, 'add feature [skip ci]'))
  end

  it 'throws an error if the current branch does not have an associated PR' do
    repository = 'org/repo'
    access_token = 'some-token'
    setup_mocks(repository, access_token)

    define_task(
      argument_names: [:branch_name]
    ) do |t, args|
      t.repository = repository
      t.access_token = access_token
      t.branch_name = args.branch_name
    end

    expect{ Rake::Task['pull_requests:merge'].invoke('branch_with_no_PR') }
      .to(raise_error(NoPullRequestError, 'No pull request associated with branch branch_with_no_PR'))
  end

  def setup_mocks(repo_name, access_token)
    agent = Sawyer::Agent.new('http://localhost')
    github_client = double('Github client')
    allow(Octokit::Client)
      .to(receive(:new)
            .with(hash_including(access_token: access_token))
            .and_return(github_client))

    allow(github_client)
      .to(receive(:pull_requests)
            .with(repo_name)
            .and_return([
              { :title => 'add feature', :number => 1, :head => { :ref => 'mergeable_branch' } },
              { :title => 'fix bug', :number => 2, :head => { :ref => 'different_branch' } }
            ]))

    allow(github_client)
      .to(receive(:merge_pull_request)
            .and_return(Sawyer::Resource.new(agent, {}))) # TODO

    return github_client
  end
end

