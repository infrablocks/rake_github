require 'spec_helper'

describe RakeGithub::Tasks::DeployKey::Ensure do
  include_context :rake

  def define_task(opts = {}, &block)
    opts = {
        namespace: :deploy_key,
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
        repository: 'org/repo',
        title: 'some-deploy-key')

    expect(Rake::Task.task_defined?('deploy_key:ensure'))
        .to(be(true))
  end

  it 'gives the ensure task a description' do
    define_task(
        repository: 'org/repo',
        title: 'some-deploy-key')

    expect(Rake::Task['deploy_key:ensure'].full_comment)
        .to(eq('Ensure deploy key some-deploy-key is configured on the ' +
            'org/repo repository'))
  end

  it 'fails if no repository is provided' do
    define_task(title: 'some-deploy-key')

    expect {
      Rake::Task['deploy_key:ensure'].invoke
    }.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no title is provided' do
    define_task(repository: 'org/repo')

    expect {
      Rake::Task['deploy_key:ensure'].invoke
    }.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'invokes destroy then provision with any defined arguments' do
    repository = 'org/repo'
    title = 'some-deploy-key'

    define_task(
        repository: repository,
        title: title,
        argument_names: [:thing1, :thing2])

    expect(Rake::Task['deploy_key:destroy'])
        .to(receive(:invoke)
            .with('value1', 'value2')
            .ordered)
    expect(Rake::Task['deploy_key:provision'])
        .to(receive(:invoke)
            .with('value1', 'value2')
            .ordered)

    Rake::Task['deploy_key:ensure'].invoke('value1', 'value2')
  end
end
