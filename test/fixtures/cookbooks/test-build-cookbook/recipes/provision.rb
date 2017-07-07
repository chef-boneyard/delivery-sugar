# Run some Terraform
#
delivery_terraform 'terraform-plans' do
  plan_dir '/path/to/plans'
  action :test
end
