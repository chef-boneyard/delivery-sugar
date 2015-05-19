require 'spec_helper'

describe DeliverySugar::Change do
  let(:node) { { 'delivery' => {'change' => {'stage' => stage,
                                             'enterprise' => 'a',
                                             'organization' => 'b',
                                             'project' => 'c',
                                             'pipeline' => 'd' }} } }
  subject { DeliverySugar::Change.new node }

  describe '#initialize' do
    let(:stage) { 'stage_name' }
    it 'sets attributes correctly' do
      expect(subject.enterprise).to eql('a')
      expect(subject.organization).to eql('b')
      expect(subject.project).to eql('c')
      expect(subject.pipeline).to eql('d')
      expect(subject.stage).to eql('stage_name')
    end
  end

  describe '#acceptance_environment' do
    let(:stage) { 'stage_name' }
    it 'returns the fully qualified environment name' do
      expect(subject.acceptance_environment).to eql('acceptance-a-b-c-d')
    end
  end

  describe '#environment_for_current_stage' do
    context 'when current stage is acceptance' do
      let(:stage) { 'acceptance' }

      it 'returns acceptance environment' do
        expect(subject).to receive(:acceptance_environment).and_return(:some_result)
        expect(subject.environment_for_current_stage).to eql(:some_result)
      end
    end
    context 'when the current stage is not acceptance' do
      let(:stage) {'not_acceptance'}

      it 'returns name of stage' do
        expect(subject.environment_for_current_stage).to eql('not_acceptance')
      end
    end
  end
end
