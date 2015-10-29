# Execute a test-kitchen converge and destroy in EC2
delivery_test_kitchen 'quality' do
  yaml '.kitchen.ec2.yml'
  driver 'ec2'
  action [:converge, :destroy]
end
