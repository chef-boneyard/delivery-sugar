require 'spec_helper'

describe DeliverySugar::Cookbook do
  let(:cookbook_path) { 'cookbooks/apache' }
  let(:metadata) { double('Metadata', name: 'apache', version: '0.1.0') }

  describe '#initialize' do
    before do
      allow_any_instance_of(described_class).to receive(:load_metadata)
        .with(cookbook_path).and_return(metadata)
    end

    it 'sets the variables correctly' do
      cookbook = described_class.new(cookbook_path)
      expect(cookbook.path).to eql(cookbook_path)
      expect(cookbook.name).to eql('apache')
      expect(cookbook.version).to eql('0.1.0')
    end
  end

  describe '#load_metadata' do
    let(:json_content) { nil }
    let(:rb_content) { nil }
    let(:json_path) { "#{cookbook_path}/metadata.json" }
    let(:rb_path) { "#{cookbook_path}/metadata.rb" }

    before do
      expect(Chef::Cookbook::Metadata).to receive(:new).and_return(metadata)
      allow_any_instance_of(described_class).to receive(:file_contents)
        .with(rb_path).and_return(rb_content)
      allow_any_instance_of(described_class).to receive(:file_contents)
        .with(json_path).and_return(json_content)
    end

    context 'with json file' do
      let(:json_content) { 'something' }

      it 'loads metadata' do
        expect(metadata).to receive(:from_json)
          .with(json_content).and_return(metadata)
        expect(described_class.new(cookbook_path).name).to eql('apache')
      end
    end

    context 'with rb file' do
      let(:rb_content) { 'something' }

      it 'loads metadata' do
        expect(metadata).to receive(:instance_eval)
          .with(rb_content, rb_path, 1).and_return(nil)
        expect(described_class.new(cookbook_path).name).to eql('apache')
      end
    end

    it 'raises when no metadata file is found' do
      expect { described_class.new(cookbook_path) }
        .to raise_error(DeliverySugar::Exceptions::NotACookbook)
    end
  end
end
