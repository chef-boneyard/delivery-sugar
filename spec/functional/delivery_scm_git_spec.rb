require 'spec_helper'

describe DeliverySugar::SCM::Git do
  include Chef::Mixin::ShellOut
  support_dir = File.join(TOPDIR, 'spec', 'support')
  test_repo = File.join(support_dir, 'temp')

  before(:all) do
    shell_out('git clone functional_test_repo.bundle -b master temp',
              cwd: support_dir)
  end

  after(:all) do
    FileUtils.rm_rf(test_repo)
  end

  before do
    @scm = Object.new
    @scm.extend(described_class)
  end

  describe '#changed_files' do
    context 'when there are no changed files' do
      let(:workspace) { test_repo }
      let(:branch1) { 'origin/master' }
      let(:branch2) { 'origin/topic_branch' }
      let(:empty_array) { [] }

      it 'returns an empty array' do
        expect(@scm.changed_files(workspace, branch1, branch2))
          .to eql(empty_array)
      end
    end

    context 'when there is one ore more changed files' do
      let(:workspace) { test_repo }
      let(:branch1) { 'origin/master' }
      let(:branch2) { 'origin/patchset_branch' }
      let(:non_empty_array) do
        [
          'a.txt',
          'd.txt'
        ]
      end

      it 'returns a non-empty array' do
        expect(@scm.changed_files(workspace, branch1, branch2))
          .to eql(non_empty_array)
      end
    end
  end
end
