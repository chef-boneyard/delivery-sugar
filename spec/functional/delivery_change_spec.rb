require 'spec_helper'

describe DeliverySugar::Change do
  include Chef::Mixin::ShellOut


  let(:stage) { 'unused' }
  let(:patchset_branch) { 'patchset_branch' }
  let(:pipeline) { 'pipe' }
  let(:sha) { '' }
  let(:workspace) { SUPPORT_DIR }

  let(:node) do
    {
      'delivery' => {
        'workspace' => {
          'repo' => workspace
        },
        'change' => {
          'stage' => stage,
          'enterprise' => 'ent',
          'organization' => 'org',
          'project' => 'proj',
          'pipeline' => pipeline,
          'patchset_branch' => patchset_branch,
          'sha' => sha
        }
      }
    }
  end

  subject { described_class.new(node) }

  describe '#changed_cookbooks' do
    let(:files) do
      %w(
        cookbooks/frodo/README.md
        cookbooks/frodo/metadata.rb
        cookbooks/sam/metadata.json
      )
    end

    let(:cookbooks_path) { File.join(SUPPORT_DIR, 'cookbooks')}
    let(:frodo_cookbook) { DeliverySugar::Cookbook.new(File.join(cookbooks_path, 'frodo/')) }
    let(:sam_cookbook) { DeliverySugar::Cookbook.new(File.join(cookbooks_path, 'sam/')) }

    it 'only returns one copy of each cookbook' do
      allow(subject).to receive(:changed_files).and_return(files)
      books = subject.changed_cookbooks
      expect(books.length).to eql(2)
      expect(books).to eql([frodo_cookbook, sam_cookbook])
    end
  end

  describe '#changed_files' do
    test_repo = File.join(SUPPORT_DIR, 'temp')
    let(:workspace) { test_repo }

    before do
      shell_out('git clone git_scm_spec_repo.bundle -b master temp',
                cwd: SUPPORT_DIR)
    end

    after do
      FileUtils.rm_rf(test_repo)
    end

    context 'when there are no changed files' do
      let(:pipeline) { 'master' }
      let(:patchset_branch) { 'topic_branch' }
      let(:empty_array) { [] }

      it 'returns an empty array' do
        expect(subject.changed_files).to eql(empty_array)
      end
    end

    context 'before the merge' do
      let(:pipeline) { 'master' }
      let(:patchset_branch) { 'patchset_branch' }
      let(:non_empty_array) do
        [
          'a.txt',
          'd.txt'
        ]
      end

      it 'returns the diff between the patchset branch and merge base' do
        expect(subject.changed_files).to eql(non_empty_array)
      end
    end

    context 'after the merge' do
      let(:sha) { '7680d32246a48af36849aff2468e72b5d9bad142' }
      let(:non_empty_array) do
        [
          'b.txt',
          'c.txt'
        ]
      end

      it 'returns the diff between the current and previous merge commits' do
        expect(subject.changed_files).to eql(non_empty_array)
      end
    end
  end
end
