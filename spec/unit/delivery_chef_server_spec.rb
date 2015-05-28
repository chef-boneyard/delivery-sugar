require 'spec_helper'
require 'chef/config'
require 'chef/encrypted_data_bag_item'

describe DeliverySugar::ChefServer do
  let(:example_knife_rb) { File.join(SUPPORT_DIR, 'example_knife.rb') }

  let(:example_config) do
    Chef::Config.from_file(example_knife_rb)
    config = Chef::Config.save
    Chef::Config.reset
    config
  end

  describe '#new' do
    context 'when no chef config is passed in during instantiation' do
      let(:deliv_knife_rb) { '/var/opt/delivery/workspace/.chef/knife.rb' }
      it 'defaults to the delivery knife.rb' do
        expect(Chef::Config).to receive(:from_file).with(deliv_knife_rb)
        described_class.new
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
      obj = described_class.new(example_knife_rb)
      after_config = Chef::Config.save

      expect(after_config).to eql(before_config)
      expect(obj.server_config).to eql(example_config)
    end
  end

  describe '#encrypted_data_bag_item' do
    subject { described_class.new(File.join(SUPPORT_DIR, 'example_knife.rb')) }

    let(:bag_name) { 'delivery-secrets' }
    let(:item_id) { 'ent-org-proj' }
    let(:secret_key_file) { '/etc/chef/encrypted_data_bag_secret' }
    let(:secret_file) { double('secret file') }
    let(:results) { double('decrypted hash') }

    before do
      allow(subject).to receive(:secret_key_file).and_return(secret_key_file)
    end

    it 'loads the CS config, reads the data bag item, then unloads the config' do
      expect(subject).to receive(:load_server_config)
      expect(subject).to receive(:unload_server_config)
      expect(Chef::EncryptedDataBagItem).to receive(:load_secret)
        .with(secret_key_file).and_return(secret_file)
      expect(Chef::EncryptedDataBagItem).to receive(:load)
        .with(bag_name, item_id, secret_file).and_return(results)
      expect(subject.encrypted_data_bag_item(bag_name, item_id)).to eql(results)
    end

    context 'when exception is raised' do
      it 'still unloads the server config' do
        allow(Chef::EncryptedDataBagItem).to receive(:load_secret)
          .and_raise('ERROR')
        expect { subject.encrypted_data_bag_item(bag_name, item_id) }
          .to raise_error('ERROR')
      end
    end
  end

  describe '#cheffish_details' do
    subject { described_class.new(example_knife_rb) }

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

  describe '#load_server_config' do
    subject { described_class.new(example_knife_rb) }

    it 'saves current config to the object and loads the server config' do
      Chef::Config.reset
      before_config = Chef::Config.save
      subject.send(:load_server_config)
      after_config = Chef::Config.save

      expect(subject.stored_config).to eql(before_config)
      expect(after_config).to eql(subject.server_config)
    end
  end

  describe '#unload_server_config' do
    subject { described_class.new(example_knife_rb) }

    before do
      Chef::Config.reset
      subject.send(:load_server_config)
    end

    it 'restores the saved config from memory' do
      subject.send(:unload_server_config)
      after_config = Chef::Config.save

      expect(subject.server_config).to eql(example_config)
      expect(after_config).to eql(subject.stored_config)
    end
  end
end
