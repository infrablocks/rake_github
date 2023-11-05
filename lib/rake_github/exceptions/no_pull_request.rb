# frozen_string_literal: true

module RakeGithub
  module Exceptions
    class NoPullRequest < StandardError
      attr_reader :branch_name

      def initialize(branch_name)
        @branch_name = branch_name

        super(format('No pull request associated with branch %s', branch_name))
      end
    end
  end
end
