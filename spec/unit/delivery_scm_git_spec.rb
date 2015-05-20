require 'spec_helper'

describe DeliverySugar::SCM::Git do
  before do
    @scm = Object.new
    @scm.extend(described_class)
  end

  describe '#changed_files' do
    let(:workspace) { 'workspace' }
    let(:branch1) { 'branch1' }
    let(:branch2) { 'branch2' }
    let(:cmd) { "git diff --name-only #{branch1} #{branch2}" }
    let(:options) { { cwd: workspace } }

    it 'runs a valid git command to get changed files' do
      expect(@scm).to receive(:shell_out).with(cmd, options)
      @scm.changed_files(workspace, branch1, branch2)
    end
  end
end
