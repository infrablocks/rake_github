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

        action do |t|
          client = Octokit::Client.new(access_token: access_token)

          release_options = {
            draft: t.draft,
            prerelease: t.prerelease
          }
          if t.target_commitish
            release_options[:target_commitish] = t.target_commitish
          end
          if t.release_name
            release_options[:release_name] = t.release_name
          end
          if t.body
            release_options[:body] = t.body
          end
          if t.discussion_category_name
            release_options[:discussion_category_name] =
              t.discussion_category_name
          end

          puts 'Creating release' \
               "#{t.release_name ? " '#{t.release_name}'" : ''} " \
               "with tag '#{t.tag_name}' " \
               "on '#{t.repository}' repository..."
          release = client.create_release(
            t.repository,
            t.tag_name,
            release_options
          )

          t.assets.each do |asset|
            if asset.is_a?(String)
              puts "Uploading asset '#{asset}' to release with tag '#{t.tag_name}'..."
              client.upload_asset(release.url, asset)
            else
              puts(
                "Uploading asset '#{asset[:path]}'" +
                  "#{asset[:name] ? " with name '#{asset[:name]}'" : ''} " +
                  "to release with tag '#{t.tag_name}'...")
              client.upload_asset(
                release.url, asset[:path], { name: asset[:name] })
            end
          end
        end
      end
    end
  end
end
