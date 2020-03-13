require 'spec_helper'

describe RakeGithub::Tasks::DeployKeys::Ensure do
  include_context :rake

  def define_task(opts = {}, &block)
    opts = {
        namespace: :deploy_keys,
        additional_tasks: [:provision, :destroy]
    }.merge(opts)

    namespace opts[:namespace] do
      opts[:additional_tasks].each do |t|
        task t
      end

      subject.define(opts, &block)
    end
  end

  it 'adds an ensure task in the namespace in which it is created' do
    define_task(
        repository: 'org/repo')

    expect(Rake::Task.task_defined?('deploy_keys:ensure'))
        .to(be(true))
  end

  it 'gives the ensure task a description' do
    define_task(
        repository: 'org/repo')

    expect(Rake::Task['deploy_keys:ensure'].full_comment)
        .to(eq('Ensure deploy keys are configured on the ' +
            'org/repo repository'))
  end

  it 'fails if no repository is provided' do
    define_task

    expect {
      Rake::Task['deploy_keys:ensure'].invoke
    }.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'invokes destroy then provision with any defined arguments' do
    repository = 'org/repo'

    define_task(
        repository: repository,
        argument_names: [:thing1, :thing2])

    expect(Rake::Task['deploy_keys:destroy'])
        .to(receive(:invoke)
            .with('value1', 'value2')
            .ordered)
    expect(Rake::Task['deploy_keys:provision'])
        .to(receive(:invoke)
            .with('value1', 'value2')
            .ordered)

    Rake::Task['deploy_keys:ensure'].invoke('value1', 'value2')
  end
end
