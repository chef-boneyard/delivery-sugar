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
    let(:cmd) { 'git diff --name-only abcdef branch2' }
    let(:sha_cmd) { 'git merge-base branch1 branch2' }
    let(:options) { { cwd: workspace } }
    let(:result) { double('shellout', stdout: '') }
    let(:sha) { double('shellout', stdout: 'abcdef') }

    it 'runs a valid git command to get changed files' do
      expect(@scm).to receive(:shell_out).with(sha_cmd, options).and_return(sha)
      expect(@scm).to receive(:shell_out).with(cmd, options).and_return(result)
      @scm.changed_files(workspace, branch1, branch2)
    end
  end
end
