require 'spec_helper'

describe DeliverySugar::SCM::Git do
  before do
    @scm = Object.new
    @scm.extend(described_class)
  end

  let(:workspace) { 'workspace' }
  let(:options) { { cwd: workspace } }

  describe '#changed_files' do
    let(:ref1) { 'ref1' }
    let(:ref2) { 'ref2' }
    let(:cmd) { 'git diff --name-only ref1 ref2' }
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
    let(:ref1) { 'ref1' }
    let(:ref2) { 'ref2' }
    let(:cmd) { 'git merge-base ref1 ref2' }
    let(:sha_shellout) { double('shellout', stdout: 'abcdef') }

    it 'runs a valid git command to get the merge_base' do
      expect(@scm).to receive(:shell_out!).with(cmd, options)
        .and_return(sha_shellout)

      expect(@scm.merge_base(workspace, ref1, ref2)).to eql('abcdef')
    end
  end

  describe '#read_at_revision' do
    let(:ref) { 'ref' }
    let(:path) { 'some/path' }
    let(:cmd) { 'git show ref:some/path' }
    let(:output) { 'abcdef' }
    let(:error) { false }
    let(:show_shellout) { double('shellout', stdout: output, error?: error) }

    before do
      expect(@scm).to receive(:shell_out).with(cmd, options)
        .and_return(show_shellout)
    end

    context 'with a valid ref' do
      it 'read content at that ref' do
        expect(@scm.read_at_revision(workspace, path, ref)).to eql(output)
      end
    end

    context 'when path is missing' do
      let(:error) { true }

      it 'returns nil' do
        expect(@scm.read_at_revision(workspace, path, ref)).to eql(nil)
      end
    end

    context 'ref is nil' do
      let(:ref) { nil }
      let(:cmd) { 'git show HEAD:some/path' }

      it 'returns content from HEAD' do
        expect(@scm.read_at_revision(workspace, path, ref)).to eql(output)
      end
    end
  end

  describe '#commit_log' do
    let(:ref1) { 'ref1' }
    let(:ref2) { 'ref2' }
    let(:cmd) { 'git log ref1..ref2' }
    let(:output) do
      [
        "commit ref1\nAuthor: Foo\nDate:  Mon May 8 19:19:19 2017 +0000\n\n    Test ref1",
        "commit ref2\nAuthor: Foo\nDate:  Mon May 7 19:19:19 2017 +0000\n\n    Test ref2"
      ]
    end
    let(:error) { false }
    let(:show_shellout) { double('shellout', stdout: output.join("\n"), error?: error) }

    it 'runs a valid git command to get the commit log' do
      expect(@scm).to receive(:shell_out!).with(cmd, options)
        .and_return(show_shellout)

      expect(@scm.commit_log(workspace, ref1, ref2)).to eql(output)
    end
  end
end
