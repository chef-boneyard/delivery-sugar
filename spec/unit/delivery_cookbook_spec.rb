require 'spec_helper'

describe DeliverySugar::Cookbook do
  let(:metadata) { double('Metadata', name: 'apache', version: '0.1.0') }
  before do
    allow_any_instance_of(described_class).to receive(:load_metadata)
      .with(cookbook_path).and_return(metadata)
  end

  describe '#initialize' do
    let(:cookbook_path) { 'cookbooks/apache' }
    it 'sets the variables correctly' do
      cookbook = described_class.new(cookbook_path)
      expect(cookbook.path).to eql(cookbook_path)
      expect(cookbook.name).to eql('apache')
      expect(cookbook.version).to eql('0.1.0')
    end
  end
end
