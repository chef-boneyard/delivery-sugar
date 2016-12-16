# Execute a test-kitchen converge and destroy in EC2
if workflow_stage?('acceptance')
  delivery_test_kitchen 'functional' do
    yaml '.kitchen.ec2.yml'
    driver 'ec2'
    suite 'default'
    action [:converge, :destroy]
  end
end
