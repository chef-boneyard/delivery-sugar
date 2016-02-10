current_dir = File.dirname(__FILE__)
log_location STDOUT
node_name 'delivery'
client_key "#{current_dir}/delivery.pem"
trusted_certs_dir '/etc/chef/trusted_certs'
chef_server_url 'https://172.31.6.129/organizations/chef_delivery'
encrypted_data_bag_secret '/var/opt/delivery/etc/secret'
