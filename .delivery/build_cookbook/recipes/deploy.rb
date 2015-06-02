# This phase is being skipped for the time being. In the future this phase will
# leveraged fully. The code here is now pseudo-code that I was working on. It is
# not functional. Please disregard in terms of code review for the time being.

# Pull the encrypted secrets from the Chef Server
secrets = get_project_secret

# Deploy to Github
delivery_github 'chef-cookbooks/delivery-sugar' do
  deploy_key secrets['github']
  branch node['delivery']['change']['pipeline']
  remote_url 'git@github.com:chef-cookbooks/delivery-sugar.git'
  repo_path node['delivery']['workspace']['repo']
  cache_path node['delivery']['workspace']['cache']
  action :push
end

# Deploy to Supermarket
# Note: This command cannot be a custom resource because it has an external
# dependency on the knife-supermarket gem.
cookbook_share_dir = File.join(node['delivery']['workspace']['cache'], 'cookbook-share')

directory cookbook_share_dir do
  recursive true
  action [:delete, :create]
end

link File.join(cookbook_share_dir, 'delivery-sugar') do
  to node['delivery']['workspace']['repo']
end

execute "share_to_supermarket" do
  command "knife supermarket share delivery-sugar " \
          "--supermarket-site https://supermarket.chef.io" \
          "--cookbook-path #{cookbook_share_dir}"
  not_if "knife supermarket show delivery-sugar " \
         "--supermarket-site https://supermarket.chef.io"
end
