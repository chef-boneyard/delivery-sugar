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
  supermarket_site = "https://supermarket.chef.io"
  cookbook = DeliverySugar::Cookbook.new(node['delivery']['workspace']['repo'])

  if secrets['supermarket_user'].nil? || secrets['supermarket_user'].empty?
    Chef::Log.fatal "If supermarket-custom-credentials is set to true, you must add supermarket_user to the secrets data bag."
    raise RuntimeError, "supermarket-custom-credentials was true and supermarket_user was not defined in delivery secrets."
  end

  if secrets['supermarket_key'].nil? || secrets['supermarket_key'].nil?
    Chef::Log.fatal "If supermarket-custom-credentials is set to true, you must add supermarket_key to the secrets data bag."
    raise RuntimeError, "supermarket-custom-credentials was true and supermarket_key was not defined in delivery secrets."
  end

  execute "share_cookbook_to_supermarket_#{cookbook.name}" do
    command "echo '#{secrets['supermarket_key']}' | knife supermarket " \
            "share #{cookbook.name} " \
            "--cookbook-path #{cookbook.path} " \
            "--config #{delivery_knife_rb} " \
            "--supermarket-site #{supermarket_site} " \
            "-u #{secrets['supermarket_user']} " \
            "-k /dev/stdin"
    not_if "knife supermarket show #{cookbook.name} #{cookbook.version} " \
            "--config #{delivery_knife_rb} " \
            "--supermarket-site #{supermarket_site}"
  end
end
