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
    let(:sha_shellout) { double('shellout', stdout: 'abcdef') }
    let(:diff_shellout) do
      double('shellout', stdout: "src/file1.txt\ntest/file2.txt\n")
    end

    it 'runs a valid git command to get changed files' do
      expect(@scm).to receive(:shell_out).with(sha_cmd, options)
        .and_return(sha_shellout)
      expect(@scm).to receive(:shell_out).with(cmd, options)
        .and_return(diff_shellout)

      expect(@scm.changed_files(workspace, branch1, branch2))
        .to eql(['src/file1.txt', 'test/file2.txt'])
    end
  end
end
