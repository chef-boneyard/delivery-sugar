delivery_test_kitchen do
  yaml '.kitchen.ec2.yml'
  driver 'ec2'
  action [:verify, :destroy]
end
