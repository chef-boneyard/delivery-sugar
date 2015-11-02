require 'spec_helper'
require 'chef/node'
require 'chef/event_dispatch/dispatcher'
require 'chef/run_context'

describe Chef::Provider::DeliveryTestKitchen do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:new_resource) { Chef::Resource::DeliveryTestKitchen.new('unit_test') }
  let(:provider) { described_class.new(new_resource, run_context) }

  before(:each) do
    allow_any_instance_of(DeliverySugar::DSL).to receive(:node)
      .and_return(cli_node)
  end

  let(:shellout_options) do
    {
      cwd: 'workspace/repo',
      env: {
        'GIT_SSH' => 'workspace/cache/git_ssh'
      }
    }
  end

  context 'when driver is set to an unsupported one' do
    before { new_resource.driver 'docker' }

    it 'raise an error' do
      expect { provider.test_kitchen.run('test') }.to raise_error(
        RuntimeError, "The test kitchen driver 'docker' is not supported"
      )
    end
  end

  context 'when driver is set to a supported one: [ec2]' do
    before { new_resource.driver 'ec2' }

    describe '#initialize' do
      subject { provider.test_kitchen }

      it 'creates a new DeliverySugar::TestKitchen with default attrs' do
        expect(subject).to be_a(DeliverySugar::TestKitchen)
        expect(subject.yaml).to eql('.kitchen.yml')
        expect(subject.suite).to eql('all')
        expect(subject.repo_path).to eql('/workspace/path/to/phase/repo')
      end
    end

    describe '#action_create' do
      it 'calls a kitchen create run' do
        expect(provider.test_kitchen).to receive(:run).with('create')
        provider.send(:action_create)
      end
    end

    describe '#action_converge' do
      it 'calls a kitchen converge run' do
        expect(provider.test_kitchen).to receive(:run).with('converge')
        provider.send(:action_converge)
      end
    end

    describe '#action_setup' do
      it 'calls a kitchen setup run' do
        expect(provider.test_kitchen).to receive(:run).with('setup')
        provider.send(:action_setup)
      end
    end

    describe '#action_verify' do
      it 'calls a kitchen verify run' do
        expect(provider.test_kitchen).to receive(:run).with('verify')
        provider.send(:action_verify)
      end
    end

    describe '#action_destroy' do
      it 'calls a kitchen destroy run' do
        expect(provider.test_kitchen).to receive(:run).with('destroy')
        provider.send(:action_destroy)
      end
    end

    describe '#action_test' do
      it 'calls a kitchen test run with options --destroy=always' do
        expect(provider.test_kitchen).to receive(:run).with('test')
        provider.send(:action_test)
        expect(provider.test_kitchen.options).to eql(' --destroy=always')
      end
    end
  end
end
