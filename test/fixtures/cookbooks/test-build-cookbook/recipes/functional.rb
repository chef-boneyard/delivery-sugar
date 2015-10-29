# with_server_config { get_project_secrets }

delivery_test_kitchen 'functional test' do
  driver 'ec2'
  repo_path delivery_workspace_repo
end
