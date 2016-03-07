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

  describe "#checkout" do
    let(:original_ref_out) { double('shellout', stdout: original_ref) }

    context 'when repo is checked out to a named ref' do
      let(:original_ref) { 'original/branch/name' }

      before(:each) do
        expect(@scm).to receive(:shell_out!).with("git rev-parse --abbrev-ref HEAD", options).and_return(original_ref_out)
        expect(@scm).to receive(:shell_out!).with("git checkout #{original_ref}", options)
      end

      it 'will run the provided block when the given sha is checked out' do
        other_sha = "somerandomsha"
        expect(@scm).to receive(:shell_out!).with("git checkout #{other_sha}", options)
        result = @scm.checkout(workspace, other_sha) { "foo" }
        expect(result).to eql("foo")
      end

      it 'will restore the git repo back to the original checkout even when exception are thrown' do
        other_sha = "somerandomsha"
        expect(@scm).to receive(:shell_out!).with("git checkout #{other_sha}", options)
        expect { @scm.checkout(workspace, other_sha) { raise "DummyException" } }.to raise_error(RuntimeError)
      end
    end

    context 'when repo has a detached HEAD' do
      let(:original_ref) { 'fakefakebasesha' }

      before(:each) do
        expect(@scm).to receive(:shell_out!).with("git rev-parse --abbrev-ref HEAD", options)
          .and_return(double('shellout', stdout: "HEAD"))
        expect(@scm).to receive(:shell_out!).with("git rev-parse HEAD", options)
          .and_return(original_ref_out)
        expect(@scm).to receive(:shell_out!).with("git checkout #{original_ref}", options)
      end

      it 'will run the provided block when the given sha is checked out' do
        other_sha = "somerandomsha"
        expect(@scm).to receive(:shell_out!).with("git checkout #{other_sha}", options)
        result = @scm.checkout(workspace, other_sha) { "foo" }
        expect(result).to eql("foo")
      end

      it 'will restore the git repo back to the original checkout even when exception are thrown' do
        other_sha = "somerandomsha"
        expect(@scm).to receive(:shell_out!).with("git checkout #{other_sha}", options)
        expect { @scm.checkout(workspace, other_sha) { raise "DummyException" } }.to raise_error(RuntimeError)
      end
    end
  end
end
