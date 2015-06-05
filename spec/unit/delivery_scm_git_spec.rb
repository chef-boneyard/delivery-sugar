require 'spec_helper'

describe DeliverySugar::SCM::Git do
  before do
    @scm = Object.new
    @scm.extend(described_class)
  end

  describe '#changed_files' do
    let(:workspace) { 'workspace' }
    let(:ref1) { 'ref1' }
    let(:ref2) { 'ref2' }
    let(:cmd) { 'git diff --name-only ref1 ref2' }
    let(:options) { { cwd: workspace } }
    let(:diff_shellout) do
      double('shellout', stdout: "src/file1.txt\ntest/file2.txt\n")
    end

    it 'runs a valid git command to get changed files' do
      expect(@scm).to receive(:shell_out!).with(cmd, options)
        .and_return(diff_shellout)

      expect(@scm.changed_files(workspace, ref1, ref2))
        .to eql(['src/file1.txt', 'test/file2.txt'])
    end
  end

  describe '#merge_base' do
    let(:workspace) { 'workspace' }
    let(:ref1) { 'ref1' }
    let(:ref2) { 'ref2' }
    let(:cmd) { 'git merge-base ref1 ref2' }
    let(:options) { { cwd: workspace } }
    let(:sha_shellout) { double('shellout', stdout: 'abcdef') }

    it 'runs a valid git command to get the merge_base' do
      expect(@scm).to receive(:shell_out!).with(cmd, options)
        .and_return(sha_shellout)

      expect(@scm.merge_base(workspace, ref1, ref2)).to eql('abcdef')
    end
  end
end
