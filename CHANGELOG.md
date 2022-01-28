# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com)
and this project adheres to
[Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [0.9.0] 2022-01-28

### Added

* New task `pull_requests:merge[branch_name,commit_message]` to merge the PR associated with the specified branch.

  `commit_message` is optional, and can contain the original commit message with the `%s` placeholder, e.g. `pull_requests:merge[new_feature,"%s [skip ci]"]`.

  Make sure to pass through `branch_name` and `commit_message` when defining your rake task:
  ```ruby
  RakeGithub.define_repository_tasks(
    # ...
  ) do |t, args|
    # ...
    t.branch_name = args.branch_name
    t.commit_message = args.commit_message
  end
  ```
