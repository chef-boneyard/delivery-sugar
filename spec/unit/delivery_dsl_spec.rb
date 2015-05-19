require 'spec_helper'

describe DeliverySugar::Delivery do
  describe '.environment_for_current_stage' do
    let(:node) { { 'delivery' => {'change' => {'stage' => stage, 'enterprise' => 'a', 'organization' => 'b', 'project' => 'c', 'pipeline' => 'd' }} } }

    context 'when running under acceptance' do
      let(:stage) { 'acceptance' }
      let(:result) { 'foo' }
      it 'returns fully qualified environment name' do
        expect(described_class).to receive(:get_acceptance_environment).with(node).and_return(result)
        expect(described_class.environment_for_current_stage(node)).to eql(result)
      end
    end

    context 'when running under any other stage' do
      let(:stage) { 'union' }
      it 'returns the stage name' do
        expect(described_class.environment_for_current_stage(node)).to eql('union')
      end
    end
  end

  describe '.get_acceptance_environment' do
    let(:node) { { 'delivery' => {'change' => {'stage' => 'acceptance', 'enterprise' => 'a', 'organization' => 'b', 'project' => 'c', 'pipeline' => 'd' }} } }

    it 'returns the fully qualified environment name' do
      expect(described_class.get_acceptance_environment(node)).to eql('acceptance-a-b-c-d')
    end
  end
end
