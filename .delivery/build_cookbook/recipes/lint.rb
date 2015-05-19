# Run rubocop to lint the libraries
execute "rubocop" do
  cwd node['delivery']['workspace']['repo']
end
