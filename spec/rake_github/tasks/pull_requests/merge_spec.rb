# frozen_string_literal: true

require 'spec_helper'
require 'octokit'

describe RakeGithub::Tasks::PullRequests::Merge do
  include_context 'rake'

  def define_task(opts = {}, &block)
    opts = { namespace: :pull_requests }.merge(opts)

    namespace opts[:namespace] do
      described_class.define(opts, &block)
    end
  end

  it 'adds a merge task in the namespace in which it is created' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0'
    )

    expect(Rake.application)
      .to(have_task_defined('pull_requests:merge'))
  end

  it 'gives the merge task a description' do
    define_task(
      repository: 'org/repo',
      access_token: 'some-token',
      tag_name: '0.1.0'
    )

    expect(Rake::Task['pull_requests:merge'].full_comment)
      .to(eq('Merges pull request on the specified branch in the org/repo ' \
             'repository'))
  end

  it 'fails if no repository is provided' do
    define_task do |t|
      t.access_token = 'some-token'
    end

    expect do
      Rake::Task['pull_requests:merge'].invoke('branch_name')
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no access token is provided' do
    define_task do |t|
      t.repository = 'org/repo'
    end

    expect do
      Rake::Task['pull_requests:merge'].invoke('branch_name')
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no branch_name is provided' do
    define_task do |t|
      t.repository = 'org/repo'
      t.access_token = 'some-token'
    end

    expect do
      Rake::Task['pull_requests:merge'].invoke
    end.to raise_error(RakeGithub::Exceptions::RequiredArgumentUnset)
  end

  it 'uses provided access token when communicating with Github' do
    repository = 'org/repo'
    access_token = 'some-token'

    client = stub_github_client

    stub_successful_list_pull_requests_request(
      client, repository, [
        pull_request('add feature', 1, 'mergeable_branch'),
        pull_request('fix bug', 2, 'different_branch')
      ]
    )
    stub_successful_merge_pull_request_request(
      client, repository, 1, 'add feature'
    )

    define_task do |t|
      t.repository = repository
      t.access_token = access_token
    end

    Rake::Task['pull_requests:merge'].invoke('mergeable_branch')

    expect(Octokit::Client)
      .to(have_received(:new)
            .with(hash_including(access_token:)))
  end

  it 'merges pull request associated with given branch name' do
    repository = 'org/repo'
    access_token = 'some-token'

    client = stub_github_client

    stub_successful_list_pull_requests_request(
      client, repository, [
        pull_request('add feature', 1, 'mergeable_branch'),
        pull_request('fix bug', 2, 'different_branch')
      ]
    )
    stub_successful_merge_pull_request_request(
      client, repository, 1, 'add feature'
    )

    define_task do |t, _args|
      t.repository = repository
      t.access_token = access_token
    end

    Rake::Task['pull_requests:merge'].invoke('mergeable_branch')

    expect(client)
      .to(have_received(:merge_pull_request)
            .with(repository, 1, 'add feature'))
  end

  it 'allows custom PR merge commit message' do
    repository = 'org/repo'
    access_token = 'some-token'
    commit_message = 'merge PR #1'

    client = stub_github_client

    stub_successful_list_pull_requests_request(
      client, repository, [
        pull_request('add feature', 1, 'mergeable_branch'),
        pull_request('fix bug', 2, 'different_branch')
      ]
    )
    stub_successful_merge_pull_request_request(
      client, repository, 1, 'merge PR #1'
    )

    define_task do |t|
      t.repository = repository
      t.access_token = access_token
    end

    Rake::Task['pull_requests:merge'].invoke('mergeable_branch', commit_message)

    expect(client)
      .to(have_received(:merge_pull_request)
            .with(repository, 1, commit_message))
  end

  it 'allows customisation of commit message via placeholder' do
    repository = 'org/repo'
    access_token = 'some-token'
    commit_message = '%s [skip ci]'

    client = stub_github_client

    stub_successful_list_pull_requests_request(
      client, repository, [
        pull_request('add feature', 1, 'mergeable_branch'),
        pull_request('fix bug', 2, 'different_branch')
      ]
    )
    stub_successful_merge_pull_request_request(
      client, repository, 1, 'add feature [skip ci]'
    )

    define_task do |t|
      t.repository = repository
      t.access_token = access_token
    end

    Rake::Task['pull_requests:merge'].invoke('mergeable_branch', commit_message)

    expect(client)
      .to(have_received(:merge_pull_request)
            .with(repository, 1, 'add feature [skip ci]'))
  end

  it 'throws an error if the current branch does not have an associated PR' do
    repository = 'org/repo'
    access_token = 'some-token'
    client = stub_github_client
    stub_successful_list_pull_requests_request(
      client, repository, [
        pull_request('add feature', 1, 'mergeable_branch'),
        pull_request('fix bug', 2, 'different_branch')
      ]
    )

    define_task do |t, _args|
      t.repository = repository
      t.access_token = access_token
    end

    expect do
      Rake::Task['pull_requests:merge'].invoke('branch_with_no_PR')
    end.to(raise_error(
             RakeGithub::Exceptions::NoPullRequest,
             'No pull request associated with branch branch_with_no_PR'
           ))
  end

  def pull_request(title, number, ref)
    {
      title:,
      number:,
      head: {
        ref:
      }
    }
  end

  def stub_github_client
    client = instance_double(Octokit::Client)
    allow(Octokit::Client)
      .to(receive(:new)
            .and_return(client))
    client
  end

  def stub_successful_list_pull_requests_request(
    client, repository_name, pull_requests
  )
    allow(client)
      .to(receive(:pull_requests)
            .with(repository_name)
            .and_return(pull_requests))
  end

  def stub_successful_merge_pull_request_request(
    client, repository_name, pull_request_number, commit_message
  )
    allow(client)
      .to(receive(:merge_pull_request)
            .with(repository_name, pull_request_number, commit_message)
            .and_return({}))
  end
end
