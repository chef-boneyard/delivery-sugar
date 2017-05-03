require 'spec_helper'

describe 'test-build-cookbook::functional' do
  context 'delivery test kitchen action: test' do
    let(:chef_client) do
      ChefSpec::SoloRunner.new(step_into: %w(delivery_test_kitchen)) do |node|
        node.set['delivery_builder'] = cli_node['delivery_builder']
        node.set['delivery'] = cli_node['delivery']
      end.converge(described_recipe)
    end
    let(:mock_ec2_secrets) do
      {
        'ec2' => {
          'keypair_name' => 'username',
          'access_key' => 'KEY',
          'secret_key' => 'SECRET',
          'private_key' => 'RSA PRIVATE KEY'
        }
      }
    end
    let(:mock_shell_out) do
      double('error!' => true)
    end

    before do
      allow(File).to receive(:exist?).and_return(true)
      allow_any_instance_of(DeliverySugar::TestKitchen).to receive(:shell_out)
        .and_return(mock_shell_out)
      allow(Chef::Config).to receive(:from_file)
        .with('/workspace/.chef/knife.rb')
        .and_return(true)
      stub_data_bag_item('delivery-secrets', 'ent-org-proj').and_return(mock_ec2_secrets)
    end

    it 'converges successfully' do
      expect { chef_client }.to_not raise_error
    end

    # For some reason that I cant yet understand chefspec is not able to assert
    # resources that are not in the resource_collection (means they havent run yet)
    # These resources goes directly to execute and they are listed on the
    # delayed_resources instead. Lets figure out how to assert those instead.

    # it 'installs kithen-ec2 gem' do
    #   expect(chef_client).to install_chef_gem('kitchen-ec2')
    # end

    # it 'renders credentials file' do
    #   expect(chef_client).to create_file('/workspace/cache/.aws/credentials')
    # end

    # it 'renders keypair pem file' do
    #   expect(chef_client).to create_file('/workspace/cache/.ssh/username.pem')
    # end

    # it 'creates .aws and .ssh directories' do
    #   expect(chef_client).to create_directory('/workspace/cache/.aws')
    #   expect(chef_client).to create_directory('/workspace/cache/.ssh')
    # end

    # it 'renders credentials file' do
    #   expect(chef_client).to create_file('/workspace/cache/.aws/credentials')
    # end
  end
end
