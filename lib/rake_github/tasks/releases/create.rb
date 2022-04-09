# frozen_string_literal: true

require 'rake_factory'
require 'octokit'

module RakeGithub
  module Tasks
    module Releases
      class Create < RakeFactory::Task
        default_description(RakeFactory::DynamicValue.new do |t|
          "Creates a release on the #{t.repository} repository"
        end)

        parameter :repository, required: true
        parameter :access_token, required: true
        parameter :tag_name, required: true
        parameter :target_commitish
        parameter :release_name
        parameter :body
        parameter :draft, default: false
        parameter :prerelease, default: false
        parameter :discussion_category_name
        parameter :assets, default: []

        action do |task|
          client = Octokit::Client.new(access_token: access_token)

          log_creating_release(task)
          release = create_release(client, task)

          task.assets.each do |asset|
            log_uploading_asset(task, asset)
            upload_asset(client, release, asset)
          end
        end

        private

        def log_creating_release(task)
          $stdout.puts(
            'Creating release' \
            "#{task.release_name ? " '#{task.release_name}'" : ''} " \
            "with tag '#{task.tag_name}' " \
            "on '#{task.repository}' repository..."
          )
        end

        def log_uploading_asset(task, asset)
          if asset.is_a?(String)
            $stdout
              .puts("Uploading asset '#{asset}' to release with tag "\
                    "'#{task.tag_name}'...")
          else
            $stdout
              .puts("Uploading asset '#{asset[:path]}'" \
                    "#{asset[:name] ? " with name '#{asset[:name]}'" : ''} " \
                    "to release with tag '#{task.tag_name}'...")
          end
        end

        def create_release(client, task)
          client.create_release(
            task.repository,
            task.tag_name,
            release_options(task)
          )
        end

        def upload_asset(client, release, asset)
          if asset.is_a?(String)
            client.upload_asset(release.url, asset)
          else
            client.upload_asset(
              release.url, asset[:path], { name: asset[:name] }
            )
          end
        end

        def release_options(task)
          {
            body: task.body,
            draft: task.draft,
            prerelease: task.prerelease,
            target_commitish: task.target_commitish,
            release_name: task.release_name,
            discussion_category_name: task.discussion_category_name
          }.compact
        end
      end
    end
  end
end
