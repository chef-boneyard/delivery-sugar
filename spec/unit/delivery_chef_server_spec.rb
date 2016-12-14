require 'spec_helper'
require 'chef/config'
require 'chef/encrypted_data_bag_item'
require 'chef/server_api'
require 'chef/rest'

describe DeliverySugar::ChefServer do
  let(:example_knife_rb) { File.join(SUPPORT_DIR, 'example_knife.rb') }

  let(:example_config) do
    Chef::Config.from_file(example_knife_rb)
    config = Chef::Config.save
    Chef::Config.reset
    config
  end

  subject { described_class.new(example_knife_rb) }

  describe '#new' do
    before do
      allow_any_instance_of(DeliverySugar::ChefServer).to receive(:node)
        .and_return(cli_node)
    end

    context 'when no chef config is passed in during instantiation' do
      let(:deliv_knife_rb) { '/workspace/.chef/knife.rb' }
      it 'defaults to the delivery knife.rb' do
        expect(Chef::Config).to receive(:from_file).with(deliv_knife_rb)
        described_class.new
      end

      context 'and there is a custom workspace coming from the delivery-cli' do
        let(:custom_workspace) { '/awesome/workspace' }
        let(:custom_deliv_knife_rb) { "#{custom_workspace}/.chef/knife.rb" }
        before { cli_node['delivery']['workspace_path'] = custom_workspace }

        it 'access the delivery knife.rb' do
          expect(Chef::Config).to receive(:from_file).with(custom_deliv_knife_rb)
          described_class.new
        end
      end
    end

    context 'when a specific chef config is passed in during instantation' do
      it 'uses that chef config' do
        expect(Chef::Config).to receive(:from_file).with('/my/fake/config.rb')
        described_class.new('/my/fake/config.rb')
      end
    end

    it 'loads a valid chef server configuration' do
      Chef::Config.reset
      before_config = Chef::Config.save
      obj = subject
      after_config = Chef::Config.save

      expect(after_config).to eql(before_config)
      expect(obj.server_config).to eql(example_config)
    end

    it 'saves the location of the knife.rb file' do
      Chef::Config.reset
      expect(subject.knife_rb).to eql(example_knife_rb)
    end
  end

  describe '#knife_command' do
    let(:shellout_results) { double('Mixlib::ShellOut Object') }

    it 'executes knife and returns the mixlib::shellout results' do
      expect(subject).to receive(:shell_out)
        .with("knife node list --config #{example_knife_rb}")
        .and_return(shellout_results)
      expect(subject.knife_command('node list')).to eql(shellout_results)
    end
  end

  describe '#upload_cookbook' do
    let(:results) { double }
    let(:name) { 'cookbook_name' }
    let(:path) { '/tmp/cookbooks/cookbook_name' }
    let(:cookbook_path) { '/tmp/cookbooks' }

    it 'executes `knife cookbook upload`' do
      expect(subject).to receive(:knife_command)
        .with("cookbook upload #{name} --cookbook-path #{cookbook_path}")
        .and_return(results)
      expect(subject.upload_cookbook(name, path)).to eql(results)
    end
  end

  describe '#encrypted_data_bag_item' do
    let(:bag_name) { 'delivery-secrets' }
    let(:item_id) { 'ent-org-proj' }
    let(:secret_key_file) { example_config[:encrypted_data_bag_secret] }
    let(:custom_secret_file) { '/path/to/secret/file' }
    let(:secret_file) { double('secret file') }
    let(:results) { double('decrypted hash') }

    it 'returns the decrypted data bag item' do
      expect(Chef::EncryptedDataBagItem).to receive(:load_secret)
        .with(secret_key_file).and_return(secret_file)
      expect(Chef::EncryptedDataBagItem).to receive(:load)
        .with(bag_name, item_id, secret_file).and_return(results)
      expect(subject.encrypted_data_bag_item(bag_name, item_id)).to eql(results)
    end

    it 'allows to pass a custom secret key' do
      expect(Chef::EncryptedDataBagItem).to receive(:load_secret)
        .with(custom_secret_file).and_return(secret_file)
      expect(Chef::EncryptedDataBagItem).to receive(:load)
        .with(bag_name, item_id, secret_file).and_return(results)
      expect(subject.encrypted_data_bag_item(bag_name, item_id, custom_secret_file))
        .to eql(results)
    end
  end

  describe '#chef_vault_item' do
    let(:vault_name) { 'workflow-vaults' }
    let(:item_id) { 'ent-org-project' }
    let(:results) { double('decrypted hash') }

    it 'returns a decrypted Chef Vault' do
      expect(ChefVault::Item).to receive(:load)
        .with(vault_name, item_id)
        .and_return(results)

      expect(subject.chef_vault_item(vault_name, item_id))
        .to eql(results)
    end
  end

  describe '#cheffish_details' do
    let(:expected_output) do
      {
        chef_server_url: 'https://172.31.6.129/organizations/chef_delivery',
        options: {
          client_name: 'delivery',
          signing_key_filename: File.join(SUPPORT_DIR, 'delivery.pem')
        }
      }
    end

    it 'returns a hash that can be used with Cheffish' do
      expect(subject.cheffish_details).to eql(expected_output)
    end
  end

  describe '#rest' do
    let(:type) { :GET }
    let(:path) { '/pushy/jobs' }
    let(:headers) { double('Headers - Hash') }
    let(:data) { double('API Body - Hash (or false for :get/:delete)') }
    let(:response) { double('API Response - Hash') }
    let(:rest_client) { double('Chef::ServerAPI Client', request: response) }

    it 'makes a request against Chef::ServerAPI client' do
      expect(Chef::ServerAPI).to receive(:new).with(
        example_config[:chef_server_url],
        client_name: example_config[:node_name],
        signing_key_filename: example_config[:client_key]
      ).and_return(rest_client)
      expect(rest_client).to receive(:request).with(type, path, headers, data)
        .and_return(response)
      expect(subject.rest(type, path, headers, data)).to eql(response)
    end
  end

  describe '#with_server_config' do
    it 'runs code block with the chef server\'s Chef::Config' do
      block = lambda do
        subject.with_server_config do
          Chef::Config[:chef_server_url]
        end
      end
      expect(Chef::Config[:chef_server_url])
        .not_to eql(example_config[:chef_server_url])
      expect(block.call).to match(example_config[:chef_server_url])
    end
  end

  describe '#load_server_config' do
    it 'saves current config to the object and loads the server config' do
      Chef::Config.reset
      before_config = Chef::Config.save
      subject.load_server_config
      after_config = Chef::Config.save

      expect(subject.stored_config).to eql(before_config)
      expect(after_config).to eql(subject.server_config)
    end
  end

  describe '#unload_server_config' do
    before do
      Chef::Config.reset
      subject.load_server_config
    end

    it 'restores the saved config from memory' do
      subject.unload_server_config
      after_config = Chef::Config.save

      expect(subject.server_config).to eql(example_config)
      expect(after_config).to eql(subject.stored_config)
    end
  end

  describe '#to_s' do
    it 'returns a string description' do
      expect(subject.to_s).to eql('delivery@https://172.31.6.129/organizations/chef_delivery')
    end
  end
end
