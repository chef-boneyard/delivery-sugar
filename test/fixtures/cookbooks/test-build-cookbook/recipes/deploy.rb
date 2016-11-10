# Share cookbook to Public Supermarket with `delivery` user
delivery_supermarket 'deploy_shares_cookbook_to_supermarket'

# Share cookbook with all custom options
delivery_supermarket 'share_cookbook_to_custom_supermarket' do
  site 'https://private-supermarket.example.com'
  cookbook 'awesome'
  path '/path/to/cookbook/awesome'
  config '/path/to/knife.rb'
  user 'dummy'
  key 'SECRET'
  category 'Applications'
  action :share
end
