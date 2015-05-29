%w(
  rubocop
  knife-supermarket
  chefspec
  simplecov
).each do |gem|
  chef_gem gem do
    action :upgrade
  end
end
