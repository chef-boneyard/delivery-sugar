#
# Trigger a kitchen test using Ec2 driver
#
delivery_test_kitchen 'functional_test' do
  driver 'ec2'
end
