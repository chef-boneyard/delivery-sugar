require 'spec_helper'

describe 'test-build-cookbook::deploy' do
  let(:chef_client) do
    ChefSpec::SoloRunner.new do |node|
      node.set['delivery_builder'] = cli_node['delivery_builder']
      node.set['delivery'] = cli_node['delivery']
      node.set['delivery']['workspace']['repo'] = File.join(SUPPORT_DIR,
                                                            'cookbooks',
                                                            'gandalf')
    end.converge(described_recipe)
  end

  before do
    allow(Chef::Config).to receive(:from_file)
      .with('/workspace/.chef/knife.rb')
      .and_return(true)
    allow_any_instance_of(DeliverySugar::ChefServer).to receive(:node)
      .and_return(cli_node)
  end

  it 'converges successfully' do
    expect { chef_client }.to_not raise_error
  end

  it 'shares a cookbook with all the defaults' do
    expect(chef_client).to share_delivery_supermarket(
      'deploy_shares_cookbook_to_supermarket'
    )
  end

  it 'shares a cookbook with custom attributes' do
    expect(chef_client)
      .to share_delivery_supermarket('share_cookbook_to_custom_supermarket')
      .with_user('dummy')
      .with_key('SECRET')
      .with_site('https://private-supermarket.example.com')
      .with_path('/path/to/cookbook/awesome')
      .with_cookbook('awesome')
      .with_category('Applications')
      .with_config('/path/to/knife.rb')
  end
end
