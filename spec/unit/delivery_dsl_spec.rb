require 'spec_helper'

describe DeliverySugar::DSL do
  subject do
    Object.new.extend(described_class)
  end

  let(:delivery_change) { double('DeliverySugar::Change') }

  before do
    allow(subject).to receive(:delivery_change).and_return(delivery_change)
  end

  it { is_expected.to respond_to :project_slug }
  it { is_expected.to respond_to :delivery_environment }

  describe '.delivery_environment' do
    it 'get the current environment from the Change object' do
      expect(subject.delivery_change).to receive(:environment_for_current_stage)
      subject.delivery_environment
    end
  end

  describe '.project_slug' do
    it 'gets slug from Change object' do
      expect(subject.delivery_change).to receive(:project_slug)
      subject.project_slug
    end
  end
end
