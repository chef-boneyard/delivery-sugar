# Run rspec for libraries and chefspec for custom resources
execute 'rspec --format documentation --color' do
  cwd node['delivery']['workspace']['repo']
  environment("COVERAGE" => 'true')
end
