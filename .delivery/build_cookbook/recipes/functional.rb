if workflow_stage?('acceptance')
  # Execute a test-kitchen converge and destroy in EC2
  delivery_test_kitchen 'functional' do
    yaml '.kitchen.ec2.yml'
    driver 'ec2'
    suite 'default'
    action [:converge, :destroy]
  end

  # Load workflow_chef_vaults
  #
  # We have previously created a Vault inside `workflow_vaults`
  # in the Automate Chef Server as the README.md specifies.
  ruby_block 'get_workflow_vault_data' do
    block do
      vault = get_workflow_vault_data
      puts "\nFunctional ChefVault Data: #{vault['data']}"
    end
  end
end
