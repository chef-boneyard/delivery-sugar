require 'spec_helper'

describe 'test-build-cookbook::with_server_config' do
  let(:chef_client) do
    ChefSpec::SoloRunner.new do |node|
      node.set['delivery_builder'] = cli_node['delivery_builder']
      node.set['delivery'] = cli_node['delivery']
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

  it 'runs the log resource with_server_config' do
    expect(chef_client).to write_log('using server config')
  end
end
