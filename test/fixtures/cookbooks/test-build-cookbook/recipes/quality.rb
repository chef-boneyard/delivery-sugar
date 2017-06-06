#
# Trigger a kitchen verify & destroy actions using Ec2 driver
# and poiting to .kitchen.ec2.yml file inside the repo_path
#
delivery_test_kitchen 'quality_verify_destroy' do
  yaml '.kitchen.ec2.yml'
  driver 'ec2'
  repo_path delivery_workspace_repo
  action [:verify, :destroy]
end

#
# Trigger a kitchen create passing extra options for debugging
#
delivery_test_kitchen 'quality_create' do
  driver 'ec2'
  options '--log-level=debug'
  action :create
end

#
# Trigger a kitchen create extending the timeout to 20 minutes
#
delivery_test_kitchen 'quality_create_with_timeout' do
  driver 'ec2'
  suite 'default'
  timeout 1200
  action :create
end
