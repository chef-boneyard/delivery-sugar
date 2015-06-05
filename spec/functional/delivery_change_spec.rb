require 'spec_helper'

describe DeliverySugar::Change do
  let(:stage) { 'unused' }
  let(:patchset_branch) { 'patchset_branch' }
  let(:sha) { '' }

  let(:node) do
    {
      'delivery' => {
        'workspace' => {
          'repo' => SUPPORT_DIR
        },
        'change' => {
          'stage' => stage,
          'enterprise' => 'ent',
          'organization' => 'org',
          'project' => 'proj',
          'pipeline' => 'pipe',
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
end
