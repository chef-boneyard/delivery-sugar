# Run some Terraform
#
delivery_terraform 'terraform-plans' do
  timeout 1200
  plan_dir "#{workflow_workspace_repo}/.delivery/build_cookbook/files/default/terraform"
end
