# Run some Terraform
#
delivery_terraform 'terraform-plans' do
  plan_dir "#{delivery_workspace_repo}/.delivery/build_cookbook/files/default/terraform"
end
