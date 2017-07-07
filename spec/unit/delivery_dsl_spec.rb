require 'spec_helper'

describe DeliverySugar::DSL do
  let(:example_knife_rb) { File.join(SUPPORT_DIR, 'example_knife.rb') }
  let(:example_config) do
    Chef::Config.from_file(example_knife_rb)
    config = Chef::Config.save
    Chef::Config.reset
    config
  end
  let(:custom_workspace) { '/var/my/awesome/workspace' }
  let(:default_workspace) { '/workspace' }

  subject do
    Object.new.extend(described_class)
  end

  before do
    allow_any_instance_of(DeliverySugar::DSL).to receive(:node)
      .and_return(cli_node)
  end

  describe '#automate_knife_rb' do
    context 'when node attribute is set from the delivery-cli' do
      before { cli_node['delivery']['workspace_path'] = custom_workspace }
      it 'returns the custom delivery knife.rb' do
        expect(subject.automate_knife_rb).to eq("#{custom_workspace}/.chef/knife.rb")
      end
    end

    context 'when node attribute is not set' do
      it 'returns the default delivery knife.rb' do
        expect(subject.automate_knife_rb).to eq("#{default_workspace}/.chef/knife.rb")
      end
    end
  end

  describe '#workflow_workspace' do
    context 'when node attribute is set from the delivery-cli' do
      before { cli_node['delivery']['workspace_path'] = custom_workspace }
      it 'returns the custom workspace' do
        expect(subject.workflow_workspace).to eq(custom_workspace)
      end
    end

    context 'when old version of delivery-cli sets partial attribute' do
      it 'returns the default workspace' do
        expect(subject.workflow_workspace).to eq(default_workspace)
      end
    end

    context 'when node attribute is not set' do
      it 'returns the default workspace' do
        expect(subject.workflow_workspace).to eq(default_workspace)
      end
    end
  end

  describe '#with_server_config' do
    before do
      allow_any_instance_of(DeliverySugar::DSL).to receive(:delivery_knife_rb)
        .and_return(example_knife_rb)
    end

    it 'runs code block with the chef server\'s Chef::Config' do
      block = lambda do
        subject.with_server_config do
          Chef::Config[:chef_server_url]
        end
      end
      expect(Chef::Config[:chef_server_url])
        .not_to eql(example_config[:chef_server_url])
      expect(block.call).to match(example_config[:chef_server_url])
    end
  end

  describe '#run_recipe_against_automate_chef_server' do
    before do
      allow_any_instance_of(DeliverySugar::DSL).to receive(:delivery_knife_rb)
        .and_return(example_knife_rb)
    end

    it 'calls chef_server.load_server_config' do
      subject.run_recipe_against_automate_chef_server
      expect(Chef::Config[:chef_server_url]).to eql(example_config[:chef_server_url])
    end
  end

  describe '#get_all_project_cookbooks' do
    it 'calls get_all_project_cookbooks on the change object' do
      expect(subject).to receive_message_chain(:change,
                                               :get_all_project_cookbooks)
      subject.get_all_project_cookbooks
    end
  end

  describe '#define_project_application' do
    it 'calls define_project_application on the change object' do
      expect(subject).to receive_message_chain(:change,
                                               :define_project_application)
      subject.define_project_application('test', '1.2.3', {})
    end
  end

  describe '#get_project_application' do
    it 'calls get_project_application on the change object' do
      expect(subject).to receive_message_chain(:change,
                                               :get_project_application)
      subject.get_project_application('test')
    end
  end

  describe '.changed_cookbooks' do
    it 'gets a list of changed cookbook from the change object' do
      expect(subject).to receive_message_chain(:change,
                                               :changed_cookbooks)
      subject.changed_cookbooks
    end
  end

  describe '.changed_files' do
    it 'gets a list of changed files from the change object' do
      expect(subject).to receive_message_chain(:change, :changed_files)
      subject.changed_files
    end
  end

  describe '.changed_dirs' do
    let(:depth) { 1 }
    it 'gets a list of changed directories based on the changed files' do
      expect(subject).to receive_message_chain(:change, :changed_dirs).with(depth)
      subject.changed_dirs(depth)
    end
  end

  describe '.change_log' do
    it 'gets a list of commit log entries' do
      expect(subject).to receive_message_chain(:change, :change_log)
      subject.change_log
    end
  end

  describe '.automate_chef_server_details' do
    let(:chef_server_configuration) { double 'a configuration hash' }

    it 'returns a cheffish configuration for interacting with the chef server' do
      expect(subject).to receive_message_chain(:automate_chef_server, :cheffish_details)
        .and_return(chef_server_configuration)

      expect(subject.automate_chef_server_details).to eql(chef_server_configuration)
    end
  end

  describe '.workflow_chef_environment_for_stage' do
    it 'get the current environment from the Change object' do
      expect(subject).to receive_message_chain(:change,
                                               :environment_for_current_stage)
      subject.workflow_chef_environment_for_stage
    end
  end

  describe '.workflow_project_acceptance_environment' do
    it 'gets the acceptance environment for the pipeline from the change object' do
      expect(subject).to receive_message_chain(:change,
                                               :acceptance_environment)
      subject.workflow_project_acceptance_environment
    end
  end

  describe '.workflow_project_slug' do
    it 'gets slug from Change object' do
      expect(subject).to receive_message_chain(:change, :project_slug)
      subject.workflow_project_slug
    end
  end

  describe '.get_project_secrets' do
    let(:project_slug) { 'ent-org-proj' }
    let(:data_bag_contents) do
      {
        'id' => 'ent-org-proj',
        'secret' => 'password'
      }
    end

    it 'gets the secrets from the project level' do
      expect(subject).to receive_message_chain(:change, :project_slug)
        .and_return(project_slug)
      expect(subject)
        .to receive_message_chain(:automate_chef_server, :data_bag_item)
        .with('delivery-secrets', project_slug, nil).and_return(data_bag_contents)

      expect(subject.get_project_secrets).to eql(data_bag_contents)
    end
  end

  describe '.get_organization_secrets' do
    let(:organization_slug) { 'ent-org' }
    let(:data_bag_contents) do
      {
        'id' => 'ent-org',
        'secret' => 'password'
      }
    end

    it 'gets the secrets from the organization level' do
      expect(subject).to receive_message_chain(:change, :organization_slug)
        .and_return(organization_slug)
      expect(subject)
        .to receive_message_chain(:automate_chef_server, :data_bag_item)
        .with('delivery-secrets', organization_slug, nil).and_return(data_bag_contents)

      expect(subject.get_organization_secrets).to eql(data_bag_contents)
    end
  end

  describe '.get_chef_vault' do
    it 'returns a Chef Vault item' do
      allow(subject)
        .to receive_message_chain(:automate_chef_server, :chef_vault_item)
        .with('workflow-vaults', 'ent')
        .and_return(id: 'ent', data: 'data')

      expect(subject.get_chef_vault('workflow-vaults', 'ent'))
        .to eql(id: 'ent', data: 'data')
    end
  end

  describe '.get_chef_vault_data_list' do
    let(:node) do
      {
        'delivery_builder' => {
          'build_user' => 'dbuild'
        },
        'delivery' => {
          'workspace' => {
            'repo' => 'workspace_repo',
            'cache' => 'workspace_cache',
            'chef' => 'workspace_chef'
          },
          'change' => {
            'stage' => 'stage_name',
            'enterprise' => 'ent',
            'organization' => 'org',
            'project' => 'proj',
            'pipeline' => 'pipe',
            'patchset_branch' => 'patchset_branch',
            'sha' => ''
          }
        }
      }
    end

    let(:enterprise_vault) do
      { id: 'ent', ent_data: 'data' }
    end

    let(:organization_vault) do
      { id: 'ent-org', org_data: 'data' }
    end

    let(:project_vault) do
      { id: 'ent-org-proj', project_data: 'data' }
    end

    before do
      allow(subject).to receive(:change).and_return(DeliverySugar::Change.new(node))
      allow_any_instance_of(DeliverySugar::DSL).to receive(:delivery_knife_rb)
        .and_return(example_knife_rb)
    end

    context 'when all vaults are present' do
      let(:chef_vault_data_list) do
        [enterprise_vault, organization_vault, project_vault]
      end

      before do
        allow(ChefVault::Item).to receive(:load)
          .with('workflow-vaults', 'ent')
          .and_return(enterprise_vault)
        allow(ChefVault::Item).to receive(:load)
          .with('workflow-vaults', 'ent-org')
          .and_return(organization_vault)
        allow(ChefVault::Item).to receive(:load)
          .with('workflow-vaults', 'ent-org-proj')
          .and_return(project_vault)
      end

      it 'returns a complete list of Chef Vaults' do
        expect(subject.get_chef_vault_data_list).to eql(chef_vault_data_list)
      end
    end

    context 'when a vault is missing' do
      let(:incomplete_chef_vault_data_list) do
        [enterprise_vault, organization_vault, {}]
      end

      before do
        allow(ChefVault::Item).to receive(:load)
          .with('workflow-vaults', 'ent')
          .and_return(enterprise_vault)
        allow(ChefVault::Item).to receive(:load)
          .with('workflow-vaults', 'ent-org')
          .and_return(organization_vault)
        allow(ChefVault::Item).to receive(:load)
          .with('workflow-vaults', 'ent-org-proj')
          .and_raise(ChefVault::Exceptions::KeysNotFound)
      end

      it 'returns a list of Chef Vaults containing an empty hash' do
        expect(subject.get_chef_vault_data_list).to eql(incomplete_chef_vault_data_list)
      end
    end
  end

  describe '.get_chef_vault_data' do
    let(:vault_data_list) do
      [
        { ent_data: 'from_ent_vault', overwritten: 'no' },
        { org_data: 'from_org_vault', overwritten: 'no' },
        { project_data: 'from_project_vault', overwritten: 'yes' }
      ]
    end

    let(:merged_vault_data) do
      {
        ent_data: 'from_ent_vault',
        org_data: 'from_org_vault',
        project_data: 'from_project_vault',
        overwritten: 'yes'
      }
    end

    it 'returns a merged hash of Chef Vault data' do
      allow(subject).to receive(:get_chef_vault_data_list).and_return(vault_data_list)
      expect(subject.get_chef_vault_data).to eql(merged_vault_data)
    end
  end

  describe '.enterprise_slug' do
    it 'gets slug from Change object' do
      expect(subject).to receive_message_chain(:change, :enterprise_slug)
      subject.enterprise_slug
    end
  end
end
