delivery_test_kitchen do
  yaml '.kitchen.ec2.yml'
  driver 'ec2'
  repo_path delivery_workspace_repo
  action [:verify, :destroy]
end
