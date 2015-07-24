require 'spec_helper'
require 'chef/node'
require 'chef/event_dispatch/dispatcher'
require 'chef/run_context'
require 'chef/mixin/shell_out'

describe Chef::Provider::DeliveryChefCookbook do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:example_knife_rb) { File.join(SUPPORT_DIR, 'example_knife.rb') }
  let(:chef_server1) { DeliverySugar::ChefServer.new(example_knife_rb) }
  let(:new_resource) do
    @resource = Chef::Resource::DeliveryChefCookbook.new('my_cookbook')
    @resource.path '/tmp/cookbook'
    @resource.chef_server chef_server1
    @resource
  end
  let(:provider) { described_class.new(new_resource, run_context) }

  describe '#action_upload' do
    it 'uploads a chef cookbook to a Chef Server' do
      expect(provider).to receive(:upload_cookbook).with(chef_server1)
      provider.action_upload
      expect(new_resource.updated_by_last_action?).to eql(true)
    end
  end

  describe '#upload_cookbook' do
    context 'when upload succeeds' do
      let(:shellout_results) { double('Mixlib::ShellOut Object') }

      it 'returns true' do
        expect(new_resource.chef_server).to receive(:upload_cookbook)
          .with('my_cookbook', '/tmp/cookbook')
          .and_return(shellout_results)
        expect(shellout_results).to receive(:error!).and_return(nil)
        expect(provider.send(:upload_cookbook, chef_server1)).to eql(nil)
      end
    end

    context 'when upload fails' do
      let(:shellout_results) { double('cookbook_upload_results') }

      it 'raises error' do
        expect(new_resource.chef_server).to receive(:upload_cookbook)
          .with('my_cookbook', '/tmp/cookbook')
          .and_return(shellout_results)
        expect(shellout_results).to receive(:error!).and_raise('ShellCommandFailed')
        expect { provider.send(:upload_cookbook, chef_server1) }
          .to raise_error
      end
    end
  end
end
