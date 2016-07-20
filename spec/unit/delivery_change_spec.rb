require 'spec_helper'

describe DeliverySugar::Change do
  let(:stage) { 'unused' }
  let(:patchset_branch) { 'patchset_branch' }
  let(:sha) { '' }

  let(:node) do
    {
      'delivery' => {
        'workspace' => {
          'repo' => 'workspace_repo',
          'cache' => 'workspace_cache',
          'chef' => 'workspace_chef'
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

  let(:chef_server) { instance_double(DeliverySugar::ChefServer) }

  let(:app_name) { 'our_app' }
  let(:app_version) { '1.1.1' }
  let(:app_attributes) do
    {
      'attr1' => 'value1',
      'attr2' => %w(arr_value1 arr_value2)
    }
  end
  let(:expected_data_bag_item_content) do
    {
      'id' => 'ent-org-proj-our_app-1.1.1',
      'version' => app_version,
      'name' => app_name
    }.merge(app_attributes)
  end
  let(:data_bag) { instance_double(Chef::DataBag) }
  let(:data_bag_item) { instance_double(Chef::DataBagItem) }
  let(:env) { Chef::Environment.new }

  let(:code) { '200' }
  let(:exception_response) { instance_double('response') }
  let(:exception) { Net::HTTPServerException.new('msg', exception_response) }

  before do
    allow(exception_response).to receive(:code).and_return(code)
  end

  subject { DeliverySugar::Change.new(node) }

  before do
    allow(subject).to receive(:chef_server).and_return(chef_server)
  end

  describe '#initialize' do
    let(:stage) { 'stage_name' }

    it 'sets attributes correctly' do
      expect(subject.enterprise).to eql('ent')
      expect(subject.organization).to eql('org')
      expect(subject.project).to eql('proj')
      expect(subject.pipeline).to eql('pipe')
      expect(subject.stage).to eql('stage_name')
      expect(subject.patchset_branch).to eql('patchset_branch')
      expect(subject.workspace_repo).to eql('workspace_repo')
      expect(subject.merge_sha).to eql('')
    end
  end

  describe '#acceptance_environment' do
    let(:stage) { 'stage_name' }

    it 'returns the fully qualified environment name' do
      expect(subject.acceptance_environment)
        .to eql('acceptance-ent-org-proj-pipe')
    end
  end

  describe '#environment_for_current_stage' do
    context 'when current stage is acceptance' do
      let(:stage) { 'acceptance' }

      it 'returns acceptance environment' do
        expect(subject).to receive(:acceptance_environment)
          .and_return(:some_result)
        expect(subject.environment_for_current_stage).to eql(:some_result)
      end
    end

    context 'when the current stage is not acceptance' do
      let(:stage) { 'not_acceptance' }

      it 'returns name of stage' do
        expect(subject.environment_for_current_stage).to eql('not_acceptance')
      end
    end
  end

  describe '#changed_files' do
    let(:client) { double('DeliverySugar::SCM') }
    let(:list_of_files) { [] }
    let(:branch1) { 'origin/pipe' }
    let(:branch2) { 'origin/patchset_branch' }
    let(:workspace) { 'workspace_repo' }
    let(:merge_base_sha) { 'merge_base_sha' }

    context 'when merge_sha is missing' do
      it 'uses the patchset_branch for the compare' do
        allow(subject).to receive(:scm_client).and_return(client)
        expect(client).to receive(:merge_base)
          .with('workspace_repo', 'origin/pipe', 'origin/patchset_branch')
          .and_return(merge_base_sha)
        expect(client).to receive(:changed_files)
          .with(workspace, merge_base_sha, branch2).and_return(list_of_files)

        expect(subject.changed_files).to eql(list_of_files)
      end
    end

    context 'when merge_sha is present' do
      let(:patchset_branch) { '' }
      let(:sha) { 'sha' }

      it 'uses the sha~1 for the compare' do
        allow(subject).to receive(:scm_client).and_return(client)
        expect(client).to receive(:changed_files)
          .with(workspace, 'sha~1', 'sha').and_return(list_of_files)

        expect(subject.changed_files).to eql(list_of_files)
      end
    end
  end

  describe '#changed_cookbooks' do
    let(:changed_files) do
      [
        'cookbooks/a/recipe.rb',
        'cookbooks/b/attribute.rb',
        'README.md',
        '.delivery/cookbooks/kilmer/metadata.rb'
      ]
    end
    let(:result) { ['cookbooks/a', 'cookbooks/b'] }
    let(:cookbook_a) { double 'cookbook a' }
    let(:cookbook_b) { double 'cookbook b' }
    let(:proj_repo) { 'workspace_repo' }

    it 'returns a unique list of Cookbooks modified in the changeset' do
      expect(subject).to receive(:changed_files).and_return(changed_files).twice
      expect(DeliverySugar::Cookbook).to receive(:new)
        .with('workspace_repo/cookbooks/a').and_return(cookbook_a)
      expect(DeliverySugar::Cookbook).to receive(:new)
        .with('workspace_repo/cookbooks/b').and_return(cookbook_b)
      expect(DeliverySugar::Cookbook).to receive(:new)
        .with('workspace_repo/').and_return(nil)

      expect(subject.changed_cookbooks).to eql([cookbook_a, cookbook_b])
    end
  end

  describe '#cookbook_metadata' do
    let(:cookbook_a) { double 'cookbook a' }
    let(:workspace_repo) { 'workspace_repo' }
    let(:cookbook_relative_path) { 'cookbooks/a' }
    let(:cookbook_path) { "#{workspace_repo}/#{cookbook_relative_path}" }

    context 'with no revision' do
      it 'returns nil when the cookbook is not found' do
        expect(DeliverySugar::Cookbook).to receive(:new)
          .with(cookbook_path, nil)
          .and_raise(DeliverySugar::Exceptions::NotACookbook, cookbook_path)
        expect(subject.cookbook_metadata(cookbook_path)).to be_nil
      end

      it 'returns the version from the metadata file in the given dir' do
        expect(DeliverySugar::Cookbook).to receive(:new)
          .with(cookbook_path, nil).and_return(cookbook_a)
        expect(subject.cookbook_metadata(cookbook_path)).to eq(cookbook_a)
      end
    end

    context 'with a revision' do
      let(:scm) { double 'git' }
      let(:revision) { 'fakefake' }

      before do
        allow(subject).to receive(:scm_client).and_return(scm)
      end

      it 'returns nil when the cookbook is not found' do
        allow(scm).to receive(:read_at_revision)
          .with(workspace_repo, cookbook_relative_path, revision).and_return(nil)
        expect(DeliverySugar::Cookbook).to receive(:new)
          .with(cookbook_path, kind_of(Proc)) do |path, lam|
            expect(lam[path]).to be_nil
            raise DeliverySugar::Exceptions::NotACookbook, cookbook_path
          end
        expect(subject.cookbook_metadata(cookbook_path, revision)).to be_nil
      end

      it 'returns the version from the metadata file in the given dir' do
        allow(scm).to receive(:read_at_revision)
          .with(workspace_repo, cookbook_relative_path, revision).and_return('something')
        expect(DeliverySugar::Cookbook).to receive(:new)
          .with(cookbook_path, kind_of(Proc)) do |path, lam|
            expect(lam[path]).to eql('something')
            cookbook_a
          end
        expect(subject.cookbook_metadata(cookbook_path, revision)).to eq(cookbook_a)
      end
    end
  end

  describe '#project_slug' do
    it 'returns a composition of the ent, org and project names' do
      expect(subject.project_slug).to eql('ent-org-proj')
    end
  end

  describe '#organization_slug' do
    it 'returns a composition of the ent and org names' do
      expect(subject.organization_slug).to eql('ent-org')
    end
  end

  describe '#define_project_application' do
    context 'when the stage is build' do
      let(:stage) { 'build' }
      it 'takes in a name, version, and hash of attributes and ' \
         'updates a data bag and environment pin' do
        expect(subject).to receive(:update_data_bag_with_application_attributes)
          .with(app_name, app_version, app_attributes).and_return(data_bag)
        expect(subject).to receive(:set_application_pin_on_acceptance_environment)
          .with(app_name, app_version).and_return(env)
        subject.define_project_application(app_name, app_version, app_attributes)
      end
    end

    context 'when the stage is not build' do
      let(:stage) { 'not-build' }
      it 'raises a proper error to the user' do
        expect do
          subject.define_project_application(app_name,
                                             app_version,
                                             app_attributes)
        end.to raise_error(RuntimeError,
                           subject.wrong_stage_for_define_project_application_error)
      end
    end
  end

  describe '#update_data_bag_with_application_attributes' do
    before do
      allow(subject).to receive(:new_data_bag).and_return(data_bag)
      allow(subject).to receive(:new_data_bag_item).and_return(data_bag_item)
      allow(chef_server).to receive(:with_server_config)
    end

    context 'when app name is invalid' do
      let(:app_name) { 'invalid name' }
      it 'raises an error' do
        expect do
          subject.update_data_bag_with_application_attributes(app_name,
                                                              app_version,
                                                              app_attributes)
        end.to raise_error(RuntimeError)
      end
    end

    context 'when app version is invalid' do
      let(:app_version) { 'invalid version' }
      it 'raises an error' do
        expect do
          subject.update_data_bag_with_application_attributes(app_name,
                                                              app_version,
                                                              app_attributes)
        end.to raise_error(RuntimeError)
      end
    end

    context 'when app name and version are valid' do
      before do
        # should save data bag and data bag item
        expect(chef_server).to receive(:with_server_config).twice

        expect(data_bag).to receive(:name).once.with('proj')
        expect(data_bag_item).to receive(:data_bag).once.with('proj')

        expect(subject).to receive(:set_data_bag_item_content)
          .with(data_bag_item, expected_data_bag_item_content)
      end
      it 'updates and / or creates the project data bag with ' \
         'a app-version named data bag item that contains passed attributes' do
        expect(subject.update_data_bag_with_application_attributes(app_name,
                                                                   app_version,
                                                                   app_attributes))
          .to eql(data_bag_item)
      end
    end
  end

  describe '#set_application_pin_on_acceptance_environment' do
    before do
      allow(chef_server).to receive(:with_server_config)
      allow(subject).to receive(:save_chef_environment)
    end

    shared_examples_for 'a properly functioning env save' do
      before do
        expect(subject).to receive(:save_chef_environment).with(env)
      end

      it 'properly sets the override attributes' do
        result = subject.set_application_pin_on_acceptance_environment(app_name,
                                                                       app_version)
        expect(result.override_attributes['applications'][app_name]).to eq(app_version)
      end
    end

    context 'when load_chef_environment raises a Net::HTTPServerException' do
      before do
        allow(subject)
          .to receive(:load_chef_environment)
          .with(subject.acceptance_environment).and_raise(exception)
      end

      context 'when load_chef_environment rasies not 200 or 404' do
        let(:code) { '500' }
        it 'raises the original error' do
          expect do
            subject.set_application_pin_on_acceptance_environment(app_name, app_version)
          end.to raise_error(exception)
        end
      end

      context 'when load_chef_environment raises a 404' do
        let(:code) { '404' }
        before do
          expect(subject).to receive(:new_environment).and_return(env)
          expect(env).to receive(:name).with(subject.acceptance_environment)
          allow(subject).to receive(:create_chef_environment).and_return(env)
        end

        it 'properly creates the new env' do
          expect(subject).to receive(:create_chef_environment).with(env).and_return(env)
          subject.set_application_pin_on_acceptance_environment(app_name, app_version)
        end

        it_behaves_like 'a properly functioning env save'
      end
    end

    context 'when load_chef_environment returns a Chef::Environment' do
      before do
        allow(subject).to receive(:load_chef_environment)
          .with(subject.acceptance_environment).and_return(env)
      end

      it_behaves_like 'a properly functioning env save'
    end
  end

  describe '#get_project_application' do
    context 'when the stage is build or verify' do
      %w(build verify).each do |current_stage|
        let(:stage) { current_stage }
        it 'raises the proper user error' do
          expect { subject.get_project_application(app_name) }
            .to raise_error(RuntimeError,
                            subject.wrong_stage_for_get_project_application_error)
        end
      end
    end

    context 'when the stage is not build or verify' do
      let(:stage) { 'union' }

      before do
        allow(env.override_attributes)
          .to receive(:[]).with('applications').and_return(app_name => app_version)
      end

      context 'when load_chef_environment raises a Net::HTTPServerException' do
        before do
          allow(subject).to receive(:load_chef_environment)
            .with(stage).and_raise(exception)
        end

        context 'when load_chef_environment rasies not 200 or 404' do
          let(:code) { '500' }
          it 'raises the original error' do
            expect { subject.get_project_application(app_name) }.to raise_error(exception)
          end
        end

        context 'when load_chef_environment rasies a 404' do
          let(:code) { '404' }
          it 'raises the proper error for the user' do
            expect { subject.get_project_application(app_name) }
              .to raise_error(RuntimeError)
          end
        end
      end

      context 'when load_chef_environment properly loads the environment' do
        before(:each) do
          allow(subject).to receive(:load_chef_environment).with(stage).and_return(env)
        end

        shared_examples_for 'when the app cannot be found' do
          it 'informs the user to use the proper setup' do
            expect { subject.get_project_application(app_name) }
              .to raise_error(RuntimeError, subject.app_not_found_error(app_name))
          end
        end

        context 'when the version pin cannot be found' do
          before(:each) do
            allow(env.override_attributes)
              .to receive(:[]).with('applications').and_return({})
          end

          it_behaves_like 'when the app cannot be found'
        end

        context 'when the data bag item cannot be found' do
          let(:code) { '404' }
          before(:each) do
            expect(subject).to receive(:load_data_bag_item)
              .with('proj', subject.app_slug(app_name, app_version)).and_raise(exception)
          end

          it_behaves_like 'when the app cannot be found'
        end

        context 'when the data bag item exists' do
          before do
            expect(subject).to receive(:load_data_bag_item)
              .with('proj', subject.app_slug(app_name, app_version))
              .and_return(data_bag_item)
            allow(data_bag_item)
              .to receive(:raw_data).and_return(expected_data_bag_item_content)
          end

          it 'calls load_data_bag_item with the proper input' do
            expect(subject.get_project_application(app_name))
              .to eq(expected_data_bag_item_content)
          end
        end
      end
    end
  end
end
