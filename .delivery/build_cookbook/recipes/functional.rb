# Run functional tests against that repo exercising DeliverySugar::SCM::Git
execute 'rspec --format documentation --color spec/functional' do
  cwd node['delivery']['workspace']['repo']
end
