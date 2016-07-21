# Stage 1
#
# We will continue pushing to Github until all our customers point
# their build-cookbooks to pull from Supermarket intead. In Stage 2
# we will move the push to Github process to Acceptance.
if delivery_environment == 'delivered'
  # Pull the encrypted secrets from the Chef Server
  secrets = get_project_secrets

  # Deploy to Github
  delivery_github 'chef-cookbooks/delivery-sugar' do
    deploy_key secrets['github']
    branch node['delivery']['change']['pipeline']
    remote_url 'git@github.com:chef-cookbooks/delivery-sugar.git'
    repo_path node['delivery']['workspace']['repo']
    cache_path node['delivery']['workspace']['cache']
    action :push
  end

  # Release to Supermarket
  if secrets['supermarket_user'].nil? || secrets['supermarket_user'].empty?
    raise RuntimeError, "supermarket_user was not defined in delivery secrets."
  end

  if secrets['supermarket_key'].nil? || secrets['supermarket_key'].nil?
    raise RuntimeError, "supermarket_key was not defined in delivery secrets."
  end

  delivery_supermarket "share_cookbook_to_supermarket" do
    user secrets['supermarket_user']
    key secrets['supermarket_key']
  end
end
