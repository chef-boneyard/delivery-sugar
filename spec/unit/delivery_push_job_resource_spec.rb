require 'spec_helper'
require 'chef/resource'

describe Chef::Resource::DeliveryPushJob do
  before(:each) do
    allow_any_instance_of(DeliverySugar::DSL).to receive(:node)
      .and_return(cli_node)
    @resource = described_class.new('push_job')
  end

  describe '#initialize' do
    it 'creates a new Chef::Resource::DeliveryPushJob with default attrs' do
      expect(@resource).to be_a(Chef::Resource)
      expect(@resource).to be_a(described_class)
      expect(@resource.provider).to be(Chef::Provider::DeliveryPushJob)
      expect(@resource.chef_config_file)
        .to eql('/workspace/.chef/knife.rb')
      expect(@resource.command).to eql('push_job')
      expect(@resource.timeout).to eql(30 * 60)
      expect(@resource.nodes).to eql([])
      expect(@resource.quorum).to eql(nil)
    end

    it 'has a resource name of :delivery_push_job' do
      expect(@resource.resource_name).to eql(:delivery_push_job)
    end

    context 'when there is a custom workspace coming from the delivery-cli' do
      let(:custom_workspace) { '/awesome/workspace' }
      let(:custom_deliv_knife_rb) { "#{custom_workspace}/.chef/knife.rb" }
      before do
        allow_any_instance_of(DeliverySugar::DSL).to receive(:delivery_workspace)
          .and_return(custom_workspace)
      end

      it 'configures the right delivery knife.rb' do
        expect(described_class.new('push_job').chef_config_file)
          .to eql(custom_deliv_knife_rb)
      end
    end
  end

  describe '#chef_config_file' do
    it 'must be a string' do
      @resource.chef_config_file 'my_file'
      expect(@resource.chef_config_file).to eql('my_file')
      expect { @resource.send(:chef_config_file, ['r']) }.to raise_error(ArgumentError)
    end
  end

  describe '#command' do
    it 'requires a string' do
      @resource.command 'dance'
      expect(@resource.command).to eql('dance')
      expect { @resource.send(:command, ['r']) }.to raise_error(ArgumentError)
    end
  end

  describe '#timeout' do
    it 'requires an Integer' do
      @resource.timeout 10
      expect(@resource.timeout).to eql(10)
      expect { @resource.send(:timeout, '10') }.to raise_error(ArgumentError)
    end
  end

  describe '#nodes' do
    it 'requires an Array' do
      @resource.nodes %w(a b)
      expect(@resource.nodes).to eql(%w(a b))
      expect { @resource.send(:nodes, 'a') }.to raise_error(ArgumentError)
    end
  end

  describe '#quorum' do
    it 'requires an Integer' do
      @resource.quorum 2
      expect(@resource.quorum).to eql(2)
      expect { @resource.send(:quorum, '2') }.to raise_error(ArgumentError)
    end
  end
end
