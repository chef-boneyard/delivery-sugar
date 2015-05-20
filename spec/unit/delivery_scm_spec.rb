require 'spec_helper'

describe DeliverySugar::SCM do
  subject { described_class.new }

  it 'includes DeliverySugar::SCM::Git by default' do
    expect(subject.methods).to include(:changed_files)
  end
end
