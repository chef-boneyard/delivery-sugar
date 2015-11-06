require 'spec_helper'

describe Chef::Resource::DeliveryGithub do
  before(:each) do
    @resource = described_class.new('octo/cat')
    @resource.repo 'octo/dog'
    @resource.deploy_key 'secret'
    @resource.remote_url 'git@github.com:octo/cat.git'
    allow_any_instance_of(DeliverySugar::DSL).to receive(:node)
      .and_return(cli_node)
  end

  def assert_enforce_string(method)
    @resource.send(method, 'string')
    expect(@resource.send(method)).to eql('string')
    expect { @resource.send(method, :not_a_string) }.to raise_error(ArgumentError)
  end

  describe '#initialize' do
    it 'creates a new Chef::Resource object and sets default attributes' do
      expect(@resource).to be_a(Chef::Resource)
      expect(@resource.provider).to eql(Chef::Provider::DeliveryGithub)
      expect(@resource.name).to eql('octo/cat')
      expect(@resource.resource_name).to eql(:delivery_github)

      expect(@resource.deploy_key).to eql('secret')
      expect(@resource.branch).to eql('master')
      expect(@resource.repo).to eql('octo/dog')
      expect(@resource.remote_name).to eql('github')
      expect(@resource.tag).to eql(nil)

      expect(@resource.action).to eql(:push)
      expect(@resource.allowed_actions).to include(:push)
    end
  end

  describe '#branch' do
    it 'only accepts a String' do
      assert_enforce_string(:branch)
    end
  end

  describe '#cache_path' do
    it 'only accepts a String' do
      assert_enforce_string(:cache_path)
    end

    it 'is required' do
      resource = described_class.new('failwhale')
      expect { resource.cache_path }
        .to raise_error(Chef::Exceptions::ValidationFailed)
    end
  end

  describe '#deploy_key' do
    it 'only accepts a String' do
      assert_enforce_string(:deploy_key)
    end

    it 'is required' do
      resource = described_class.new('failwhale')
      expect { resource.deploy_key }
        .to raise_error(Chef::Exceptions::ValidationFailed)
    end
  end

  describe '#remote_name' do
    it 'only accepts a String' do
      assert_enforce_string(:remote_name)
    end
  end

  describe '#remote_url' do
    it 'only accepts a String' do
      assert_enforce_string(:remote_url)
    end

    it 'is required' do
      resource = described_class.new('failwhale')
      expect { resource.remote_url }
        .to raise_error(Chef::Exceptions::ValidationFailed)
    end
  end

  describe '#repo' do
    it 'only accepts a String' do
      assert_enforce_string(:repo)
    end

    it 'is the name attribute by default' do
      resource = described_class.new('octo/cat')
      expect(resource.repo).to eql('octo/cat')
    end
  end

  describe '#repo_path' do
    it 'only accepts a String' do
      assert_enforce_string(:repo_path)
    end

    it 'is required' do
      resource = described_class.new('failwhale')
      expect { resource.repo_path }
        .to raise_error(Chef::Exceptions::ValidationFailed)
    end
  end

  describe '#tag' do
    it 'only accepts a String' do
      assert_enforce_string(:tag)
    end
  end
end
