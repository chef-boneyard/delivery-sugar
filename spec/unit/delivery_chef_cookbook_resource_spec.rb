require 'spec_helper'

describe Chef::Resource::DeliveryChefCookbook do
  let(:example_knife_rb) { File.join(SUPPORT_DIR, 'example_knife.rb') }
  let(:chef_server1) { DeliverySugar::ChefServer.new(example_knife_rb) }
  let(:chef_server2) { DeliverySugar::ChefServer.new(example_knife_rb) }

  before(:each) do
    @resource = described_class.new('cookbook_name')
    @resource.path '/tmp/cookbook'
    @resource.chef_server chef_server1
  end

  def assert_enforce_string(method)
    @resource.send(method, 'string')
    expect(@resource.send(method)).to eql('string')
    expect { @resource.send(method, :not_a_string) }.to raise_error(ArgumentError)
  end

  describe '#initialize' do
    it 'creates a new Chef::Resource' do
      expect(@resource).to be_a(Chef::Resource)
      expect(@resource.provider).to eql(Chef::Provider::DeliveryChefCookbook)
      expect(@resource.resource_name).to eql(:delivery_chef_cookbook)
      expect(@resource.name).to eql('cookbook_name')

      expect(@resource.path).to eql('/tmp/cookbook')
      expect(@resource.chef_server).to be_a(DeliverySugar::ChefServer)

      expect(@resource.action).to eql(:upload)
      expect(@resource.allowed_actions).to include(:upload)
    end
  end

  describe '#path' do
    it 'only accepts a String' do
      assert_enforce_string(:path)
    end

    it 'is required' do
      resource = described_class.new('my_cookbook')
      expect { resource.path }.to raise_error(Chef::Exceptions::ValidationFailed)
    end
  end

  describe '#chef_server' do
    it 'only accepts a(n array of) DeliverySugar::ChefServer(s)' do
      @resource.send(:chef_server, chef_server1)
      expect(@resource.send(:chef_server)).to eql(chef_server1)

      @resource.send(:chef_server, [chef_server1, chef_server2])
      expect(@resource.send(:chef_server)).to eql([chef_server1, chef_server2])

      expect { @resource.send(:chef_server, :not_a_string) }.to raise_error(ArgumentError)
    end

    it 'is required' do
      resource = described_class.new('my_cookbook')
      expect { resource.chef_server }.to raise_error(Chef::Exceptions::ValidationFailed)
    end
  end

  describe '#cookbook_to_upload' do
    it 'only accepts a String' do
      assert_enforce_string(:cookbook_to_upload)
    end

    it 'is the name attribute by default' do
      resource = described_class.new('my_cookbook')
      expect(resource.cookbook_to_upload).to eql('my_cookbook')
    end
  end
end
