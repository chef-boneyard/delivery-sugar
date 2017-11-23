require 'spec_helper'
require 'chef/resource'

describe Chef::Resource::DeliveryTestKitchen do
  before(:each) do
    allow_any_instance_of(DeliverySugar::DSL).to receive(:node)
      .and_return(cli_node)
    @resource = described_class.new('unit_test')
  end

  describe '#initialize' do
    it 'creates a new Chef::Resource::DeliveryTestKitchen with default attrs' do
      expect(@resource).to be_a(Chef::Resource)
      expect(@resource).to be_a(described_class)
      expect(@resource.provider).to be(Chef::Provider::DeliveryTestKitchen)
      expect(@resource.yaml).to eql('.kitchen.yml')
      expect(@resource.suite).to eql('all')
      expect(@resource.repo_path).to eql('/workspace/path/to/phase/repo')
      expect(@resource.environment).to eql({})
    end

    it 'has a resource name of :delivery_test_kitchen' do
      expect(@resource.resource_name).to eql(:delivery_test_kitchen)
    end
  end

  describe '#driver' do
    it 'must be a string' do
      @resource.driver 'ec2'
      expect(@resource.driver).to eql('ec2')
      expect { @resource.send(:driver, ['r']) }.to raise_error(ArgumentError)
    end

    it 'is required' do
      resource = described_class.new('unit_test')
      expect { resource.driver }.to raise_error(Chef::Exceptions::ValidationFailed)
    end
  end

  describe '#environment' do
    it 'must be a hash' do
      @resource.environemnt {}
      expect(@resource.environment).to eql({})
      expect { @resource.send(:environment, ['r']) }.to raise_error(ArgumentError)
    end
  end

  describe '#yaml' do
    it 'requires a string' do
      @resource.yaml '.kitchen.ec2.yml'
      expect(@resource.yaml).to eql('.kitchen.ec2.yml')
      expect { @resource.send(:yaml, ['r']) }.to raise_error(ArgumentError)
    end
  end

  describe '#suite' do
    it 'requires an string' do
      @resource.suite 'default'
      expect(@resource.suite).to eql('default')
      expect { @resource.send(:suite, 10) }.to raise_error(ArgumentError)
    end
  end

  describe '#repo_path' do
    it 'requires an string' do
      @resource.repo_path '/path'
      expect(@resource.repo_path).to eql('/path')
      expect { @resource.send(:repo_path, 10) }.to raise_error(ArgumentError)
    end
  end

  describe '#options' do
    it 'requires an string' do
      @resource.options '--log-level debug'
      expect(@resource.options).to eql('--log-level debug')
      expect { @resource.send(:options, ['-d']) }.to raise_error(ArgumentError)
    end
  end
end
