require 'spec_helper'
require 'chef/node'
require 'chef/event_dispatch/dispatcher'
require 'chef/run_context'
require 'mixlib/shellout/exceptions'

describe Chef::Provider::DeliveryChefCookbook do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:example_knife_rb) { File.join(SUPPORT_DIR, 'example_knife.rb') }
  let(:chef_server1) { DeliverySugar::ChefServer.new(example_knife_rb) }
  let(:chef_server2) { DeliverySugar::ChefServer.new(example_knife_rb) }
  let(:single_server_resource) do
    @resource = Chef::Resource::DeliveryChefCookbook.new('my_cookbook')
    @resource.path '/tmp/cookbook'
    @resource.chef_server chef_server1
    @resource
  end

  let(:multi_server_resource) do
    @resource = Chef::Resource::DeliveryChefCookbook.new('my_cookbook')
    @resource.path '/tmp/cookbook'
    @resource.chef_server [chef_server1, chef_server2]
    @resource
  end

  describe '#action_upload' do
    context 'with a single chef server' do
      let(:provider) { described_class.new(single_server_resource, run_context) }

      context 'when upload succeeds' do
        it 'marks resource as updated' do
          expect(provider).to receive(:upload_cookbook).with(chef_server1).and_return(nil)
          provider.action_upload
          expect(single_server_resource.updated_by_last_action?).to eql(true)
        end
      end

      context 'when upload fails' do
        it 'fails the resource' do
          expect(provider).to receive(:upload_cookbook).with(chef_server1)
            .and_raise(Mixlib::ShellOut::ShellCommandFailed, 'Error Message')
          expect(Chef::Log).to receive(:error).with('Error Message')
          expect { provider.action_upload }
            .to raise_error(DeliverySugar::Exceptions::CookbookUploadFailed)
          expect(single_server_resource.updated_by_last_action?).to eql(false)
        end
      end
    end

    context 'with multiple chef servers' do
      let(:provider) { described_class.new(multi_server_resource, run_context) }

      context 'when all uploads succeed' do
        it 'marks resource as updated' do
          expect(provider).to receive(:upload_cookbook).with(chef_server1).and_return(nil)
          expect(provider).to receive(:upload_cookbook).with(chef_server2).and_return(nil)
          provider.action_upload
          expect(multi_server_resource.updated_by_last_action?).to eql(true)
        end
      end

      context 'when at least one upload fails' do
        it 'finishes all the uploads, then fails the resource' do
          expect(provider).to receive(:upload_cookbook).with(chef_server1).and_return(nil)
          expect(provider).to receive(:upload_cookbook).with(chef_server2)
            .and_raise(Mixlib::ShellOut::ShellCommandFailed, 'Error Message')
          expect(Chef::Log).to receive(:error).with('Error Message')
          expect { provider.action_upload }
            .to raise_error(DeliverySugar::Exceptions::CookbookUploadFailed)
          expect(multi_server_resource.updated_by_last_action?).to eql(true)
        end
      end

      context 'when all uploads fail' do
        it 'fails the resource and marks it as unchanged' do
          expect(provider).to receive(:upload_cookbook).with(chef_server1)
            .and_raise(Mixlib::ShellOut::ShellCommandFailed, 'Error Message 1')
          expect(provider).to receive(:upload_cookbook).with(chef_server2)
            .and_raise(Mixlib::ShellOut::ShellCommandFailed, 'Error Message 2')
          expect(Chef::Log).to receive(:error).with('Error Message 1')
          expect(Chef::Log).to receive(:error).with('Error Message 2')
          expect { provider.action_upload }
            .to raise_error(DeliverySugar::Exceptions::CookbookUploadFailed)
          expect(multi_server_resource.updated_by_last_action?).to eql(false)
        end
      end
    end
  end

  describe '#upload_cookbook' do
    let(:provider) { described_class.new(single_server_resource, run_context) }

    context 'when upload succeeds' do
      let(:shellout_results) { double('Mixlib::ShellOut Object') }

      it 'returns true' do
        expect(chef_server1).to receive(:upload_cookbook)
          .with('my_cookbook', '/tmp/cookbook')
          .and_return(shellout_results)
        expect(shellout_results).to receive(:error!).and_return(nil)
        expect(provider.send(:upload_cookbook, chef_server1)).to eql(nil)
      end
    end

    context 'when upload fails' do
      let(:shellout_results) { double('cookbook_upload_results') }

      it 'raises error' do
        expect(chef_server1).to receive(:upload_cookbook)
          .with('my_cookbook', '/tmp/cookbook')
          .and_return(shellout_results)
        expect(shellout_results).to receive(:error!).and_raise('ShellCommandFailed')
        expect { provider.send(:upload_cookbook, chef_server1) }
          .to raise_error
      end
    end
  end

  describe '#chef_server_list' do
    let(:provider1) { described_class.new(single_server_resource, run_context) }
    let(:provider2) { described_class.new(multi_server_resource, run_context) }
    let(:server_out) { 'delivery@https://172.31.6.129/organizations/chef_delivery' }

    it 'returns a comma-delimited list of chef servers' do
      expect(provider1.send(:chef_server_list)).to eql(server_out)
      expect(provider2.send(:chef_server_list)).to eql("#{server_out}, #{server_out}")
    end
  end
end
