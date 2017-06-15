require 'spec_helper'

describe 'test-build-cookbook::provision' do
  context 'delivery_terraform default action: test' do
    let(:chef_client) do
      ChefSpec::SoloRunner.new(step_into: %w(delivery_terraform)) do |node|
        node.set['delivery_builder'] = cli_node['delivery_builder']
        node.set['delivery'] = cli_node['delivery']
      end.converge(described_recipe)
    end
    let(:mock_shell_out) do
      double('error!' => true)
    end
    let(:node) { chef_client.node }
    let(:state_out) { "{ \"instance\" : \"running\" }" }
    let(:state_saved) { { "instance" => "running" } }

    before do
      allow_any_instance_of(Chef::Mixin::ShellOut).to receive(:shell_out)
        .and_return(mock_shell_out)
      allow(mock_shell_out).to receive(:stdout).and_return(state_out)
      ::File.stub(:exist?).with(anything).and_call_original
      ::File.stub(:exist?).with('/workspace/path/to/phase/repo').and_return true
      ::File.stub(:exist?).with('/path/to/plans').and_return true
    end

    it 'converges successfully' do
      expect { chef_client }.to_not raise_error
    end

    it 'runs the test action' do
      expect(chef_client).to test_delivery_terraform('terraform-plans')
    end

    it 'saves the state' do
      expect(node.run_state['terraform-state']).to eq(state_saved)
    end
  end
end
