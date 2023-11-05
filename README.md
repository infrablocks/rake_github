# RakeGithub

Rake tasks for managing Github repositories.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rake_github'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rake_github

## Usage

### define_deploy_keys_tasks

### define_repository_tasks

Sets up rake tasks for managing deploy keys and merging pull requests.

```ruby
require 'rake_github'

RakeGithub.define_repository_tasks(
  namespace: :github,
  repository: 'org/repo', # required
) do |t|
  t.access_token = "your_github_access_token" # required
  t.deploy_keys = [
    {
      title: 'CircleCI',
      public_key: File.read('path/to/your_deploy_key.public')
    }
  ]
end
```

| Parameter                       | Type   | Required | Description                                                | Example                                                | Default                              |
|---------------------------------|--------|----------|------------------------------------------------------------|--------------------------------------------------------|--------------------------------------|
| repository                      | string | Y        | Repository to perform tasks upon                           | 'organisation/repository_name'                         | N/A                                  |
| access_token                    | string | Y        | Github token for authorisation                             | 'ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'            | N/A                                  |
| deploy_keys                     | array  | N        | Keys to deploy to repository                               | { title: string, public_key: string, read_only: bool } | [ ]                                  |
| deploy_keys_namespace           | symbol | N        | Namespace to contain deploy keys tasks                     | :deploy_tasks                                          | :deploy_keys                         |
| deploy_keys_destroy_task_name   | symbol | N        | Option to change the destroy task name                     | :obliterate                                            | :destroy                             |
| deploy_keys_provision_task_name | symbol | N        | Option to change the provision task name                   | :add                                                   | :provision                           |
| deploy_keys_ensure_task_name    | symbol | N        | Option to change the ensure task name                      | :destroy_and_provision                                 | :ensure                              |
| namespace                       | symbol | N        | Namespace for tasks to live in, defaults to root namespace | :rake_github                                           | N/A                                  |

Exposes tasks:

```shell
$ rake -T

rake github:deploy_keys:destroy
rake github:deploy_keys:ensure
rake github:deploy_keys:provision
rake github:pull_requests:merge[branch_name,commit_message]
```

#### deploy_keys:provision

Provisions deploy keys to the specified repository.

#### deploy_keys:destroy

Destroys deploy keys from the specified repository.

#### deploy_keys:ensure

Destroys and then provisions deploy keys on the specified repository.

#### pull_requests:merge[branch_name,commit_message]

Merges the PR associated with the `branch_name`. Branch name is required.

`commit_message` is optional, and can contain the original commit message with
the `%s` placeholder, e.g. `pull_requests:merge[new_feature,"%s [skip ci]"]`.

### define_release_task

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

### Managing CircleCI keys

To encrypt a GPG key for use by CircleCI:

```bash
openssl aes-256-cbc \
  -e \
  -md sha1 \
  -in ./config/secrets/ci/gpg.private \
  -out ./.circleci/gpg.private.enc \
  -k "<passphrase>"
```

To check decryption is working correctly:

```bash
openssl aes-256-cbc \
  -d \
  -md sha1 \
  -in ./.circleci/gpg.private.enc \
  -k "<passphrase>"
```

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/infrablocks/rake_github. This project is intended to be a
safe, welcoming space for collaboration, and contributors are expected to adhere
to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).
