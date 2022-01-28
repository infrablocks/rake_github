# frozen_string_literal: true

module RakeGithub
  module Exceptions
    class NoPullRequestError < StandardError
      attr_reader :branch_name

      def initialize(branch_name)
        @branch_name = branch_name

        super('No pull request associated with branch %s' % branch_name)
      end
    end
  end
end
