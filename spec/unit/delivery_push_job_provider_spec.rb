require 'spec_helper'
require 'chef/node'
require 'chef/event_dispatch/dispatcher'
require 'chef/run_context'

describe Chef::Provider::DeliveryPushJob do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:node_objects) do
    [
      double('Chef::Node - 1'),
      double('Chef::Node - 2')
    ]
  end
  let(:chef_config_file) { '/workspace/.chef/knife.rb' }
  let(:command) { 'chef-client' }
  let(:timeout) { 10 }
  let(:quorum) { 2 }
  let(:new_resource) { Chef::Resource::DeliveryPushJob.new(command, run_context) }
  let(:provider) { described_class.new(new_resource, run_context) }

  before(:each) do
    allow_any_instance_of(DeliverySugar::DSL).to receive(:node)
      .and_return(cli_node)
    new_resource.nodes node_objects
    new_resource.timeout timeout
  end

  describe '#initialize' do
    it 'create a PushJob object' do
      expect(DeliverySugar::PushJob).to receive(:new).with(
        chef_config_file,
        command,
        node_objects,
        timeout,
        quorum
      )
      described_class.new(new_resource, nil)
    end
  end

  describe '#action_dispatch' do
    let(:push_job_client) { double('PushJob instance') }
    let(:file_exist) { true }
    before do
      allow(DeliverySugar::PushJob).to receive(:new).with(
        new_resource.chef_config_file,
        new_resource.command,
        new_resource.nodes,
        new_resource.timeout,
        new_resource.quorum
      ).and_return(push_job_client)
      allow(File).to receive(:exist?).with(chef_config_file).and_return(file_exist)
    end

    context 'when chef_config_file does not exist' do
      let(:file_exist) { false }

      it 'raises an exception' do
        expect { provider.run_action(:dispatch) }.to raise_error(
          RuntimeError,
          "The config file \"#{chef_config_file}\" does not exist."
        )
      end
    end

    context 'when the node list is empty' do
      let(:node_objects) { [] }

      it 'does nothing' do
        expect(provider.push_job).not_to receive(:dispatch)
        expect(provider.push_job).not_to receive(:wait)
        provider.run_action(:dispatch)
      end
    end

    it 'dispatches push job and waits for completion' do
      expect(new_resource).to receive(:quorum).and_return(2)
      allow(provider.push_job).to receive(:dispatch)
      allow(provider.push_job).to receive(:wait)
      expect(new_resource).to receive(:updated_by_last_action).with(true)
      provider.action_dispatch
    end
  end
end
