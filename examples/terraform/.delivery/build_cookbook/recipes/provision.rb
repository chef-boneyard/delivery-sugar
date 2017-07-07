#
# Cookbook:: build_cookbook
# Recipe:: provision
#
# Copyright:: 2017, The Authors, All Rights Reserved.
include_recipe 'delivery-truck::provision'

vault_data = get_chef_vault_data

ENV.update(
  'TF_VAR_user_name'     => vault_data['openstack']['user_name'],
  'TF_VAR_tenant_name'   => vault_data['openstack']['tenant_name'],
  'TF_VAR_password'      => vault_data['openstack']['password'],
  'TF_VAR_key_pair'      => vault_data['openstack']['key_pair'],
  'TF_VAR_private_key'   => vault_data['openstack']['private_key']
)

delivery_terraform 'terraform-plan' do
  plan_dir "#{delivery_workspace_repo}/.delivery/build_cookbook/files/default/terra_plans"
  only_if { workflow_stage?('acceptance') }
end
