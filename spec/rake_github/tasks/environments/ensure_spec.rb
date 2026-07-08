# frozen_string_literal: true

require 'spec_helper'

describe RakeGithub::Tasks::Environments::Ensure do
  include_context 'rake'

  def define_task(opts = {}, &block)
    opts = {
      namespace: :environments,
      additional_tasks: %i[provision destroy]
    }.merge(opts)

    namespace opts[:namespace] do
      opts[:additional_tasks].each do |t|
        task t
      end

      described_class.define(opts, &block)
    end
  end

  it 'adds an ensure task in the namespace in which it is created' do
    define_task(
      repository: 'org/repo'
    )

    expect(Rake.application)
      .to(have_task_defined('environments:ensure'))
  end

  it 'gives the ensure task a description' do
    define_task(
      repository: 'org/repo'
    )

    expect(Rake::Task['environments:ensure'].full_comment)
      .to(eq('Ensure environments are configured on the ' \
             'org/repo repository'))
  end

  it 'fails if no repository is provided' do
    define_task

    expect do
      Rake::Task['environments:ensure'].invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'invokes destroy then provision with any defined arguments' do
    repository = 'org/repo'

    define_task(
      repository:,
      argument_names: %i[thing1 thing2]
    )

    allow(Rake::Task['environments:destroy']).to(receive(:invoke))
    allow(Rake::Task['environments:provision']).to(receive(:invoke))

    Rake::Task['environments:ensure'].invoke('value1', 'value2')

    expect(Rake::Task['environments:destroy'])
      .to(have_received(:invoke)
            .with('value1', 'value2')
            .ordered)
    expect(Rake::Task['environments:provision'])
      .to(have_received(:invoke)
            .with('value1', 'value2')
            .ordered)
  end
  # rubocop:enable RSpec/MultipleExpectations
end
