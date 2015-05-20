# Run rspec for libraries and chefspec for custom resources
execute 'rspec --format documentation --color spec/unit' do
  cwd node['delivery']['workspace']['repo']
end
