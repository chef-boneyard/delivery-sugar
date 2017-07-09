require 'spec_helper'

describe 'test-build-cookbook::default' do
  context 'with no node[\'delivery\'] attributes set via delivery cli' do
    let(:chef_run) do
      runner = ChefSpec::ServerRunner.new(platform: 'ubuntu', version: '16.04')
      runner.converge(described_recipe)
    end

    it 'compiles and converges successfully' do
      expect { chef_run }.to_not raise_error
    end
  end
end
