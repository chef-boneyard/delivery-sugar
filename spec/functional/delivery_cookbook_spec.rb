require 'spec_helper'
require 'chef/cookbook/metadata'

describe DeliverySugar::Cookbook do
  it 'loads a cookbook that has a metadata.rb' do
    cookbook_path = File.join(SUPPORT_DIR, 'cookbooks', 'frodo')
    obj = described_class.new(cookbook_path)
    expect(obj.name).to eql('frodo')
    expect(obj.path).to eql(cookbook_path)
    expect(obj.version).to eql('0.1.0')
  end

  it 'loads a cookbook that has a metadata.json' do
    cookbook_path = File.join(SUPPORT_DIR, 'cookbooks', 'sam')
    obj = described_class.new(cookbook_path)
    expect(obj.name).to eql('sam')
    expect(obj.path).to eql(cookbook_path)
    expect(obj.version).to eql('0.1.0')
  end

  it 'raises exception when metadata is missing' do
    cookbook_path = File.join(SUPPORT_DIR, 'cookbooks', 'smeagol')
    expect { described_class.new(cookbook_path) }
      .to raise_error(DeliverySugar::Exceptions::NotACookbook)
  end

  describe '#==' do
    it 'returns true when the cookbooks are the same' do
      c1 = c2 = described_class.new(File.join(SUPPORT_DIR, 'cookbooks', 'frodo'))
      expect(c1).to eql(c2)
    end

    it 'returns false when the cookbooks are different' do
      c1 = described_class.new(File.join(SUPPORT_DIR, 'cookbooks', 'frodo'))
      c2 = described_class.new(File.join(SUPPORT_DIR, 'cookbooks', 'sam'))
      expect(c1).not_to eql(c2)
    end
  end
end
