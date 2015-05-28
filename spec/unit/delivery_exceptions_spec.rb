require 'spec_helper'

describe DeliverySugar::Exceptions::NotACookbook do
  subject { described_class.new('/path') }
  describe '#new' do
    it 'is a Runtime error that accepts a path' do
      expect(subject).to be_a RuntimeError
      expect(subject.path).to eql('/path')
    end
  end

  describe '#to_s' do
    let(:output) do
      <<-EOM
The directory below is not a valid cookbook:
/path
      EOM
    end

    it 'prints out a helpful error message with a path' do
      expect(subject.to_s).to eql(output)
    end
  end
end
