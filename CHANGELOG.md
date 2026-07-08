# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com)
and this project adheres to
[Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## Unreleased

### Added

* New `secrets` task group, defined via `RakeGithub.define_secrets_tasks`, for
  managing GitHub repository secrets. It exposes `provision`, `destroy` and
  `ensure` tasks. Each secret is written to the Actions secret store, and
  additionally to the Dependabot secret store when it sets `dependabot: true`,
  so that Dependabot-triggered workflow runs can read the secrets they need.

  Secrets are supplied as an array of hashes, e.g.
  `[{ name: 'SOME_SECRET', value: 'plaintext' }]`, and are encrypted
  client-side before being sent to GitHub.

* The `secrets` task group is also included in the tasks defined by
  `RakeGithub.define_repository_tasks`.

* New `environments` task group, defined via
  `RakeGithub.define_environments_tasks`, for managing GitHub deployment
  environments. It exposes `provision`, `destroy` and `ensure` tasks, and
  supports protection rules including required reviewers.

  Environments are supplied as an array of hashes, e.g.
  `[{ name: 'release', reviewers: [{ team: 'maintainers' }] }]`. Only `name`
  is required; team and user reviewers are resolved to their numeric ids
  before being sent to GitHub.

* The `environments` task group is also included in the tasks defined by
  `RakeGithub.define_repository_tasks`.

### Changed

* The `pull_requests:merge` task no longer requires setting the branch name and
  commit message provide via arguments as parameters within the task definition.
* The `octokit` dependency lower bound has been raised from `>= 4.16` to
  `>= 7.0`, as the Dependabot secret methods used by the `secrets` task group
  were introduced in octokit 7.0. Consumers pinning octokit below 7.0 will need
  to relax that constraint.
* Added a new runtime dependency on `rbnacl` (`~> 7.1`), used to encrypt
  secrets client-side. `rbnacl` requires the native libsodium library to be
  installed on the host (see the Installation section of the README); this is
  only needed when using the `secrets` task group.

## [0.9.0] 2022-01-28

### Added

* New task `pull_requests:merge[branch_name,commit_message]` to merge the PR 
  associated with the specified branch.

  `commit_message` is optional, and can contain the original commit message with
  the `%s` placeholder, e.g. `pull_requests:merge[new_feature,"%s [skip ci]"]`.

  Make sure to pass through `branch_name` and `commit_message` when defining
  your rake task:
  
  ```ruby
  RakeGithub.define_repository_tasks(
    # ...
  ) do |t, args|
    # ...
    t.branch_name = args.branch_name
    t.commit_message = args.commit_message
  end
  ```
