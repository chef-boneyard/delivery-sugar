#
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module DeliverySugar
  #
  # This is class we will use to interface with Chef Servers.
  #
  class ChefServer
    attr_reader :server_config, :stored_config

    #
    # Initialize a new Chef Server object
    #
    # @param chef_config_rb [String]
    #   The fully-qualified path to a chef config file to load settings from.
    #
    # @return [DeliverySugar::ChefServer]
    #
    def initialize(chef_config_rb = delivery_knife_rb)
      before_config = Chef::Config.save
      Chef::Config.from_file(chef_config_rb)
      @server_config = Chef::Config.save
      Chef::Config.restore(before_config)
    end

    #
    # Return the decrypted contents of an encrypted data bag from the Chef
    # Server.
    #
    # @param bag_name [String]
    #   The name of the data bag
    # @param item_id [String]
    #   The name of the data bag item
    #
    # @return [Hash]
    #
    def encrypted_data_bag_item(bag_name, item_id)
      load_server_config
      secret_file = Chef::EncryptedDataBagItem.load_secret(secret_key_file)
      Chef::EncryptedDataBagItem.load(bag_name, item_id, secret_file)
    ensure
      unload_server_config
    end

    #
    # Return a hash that can be fed into Cheffish resources.
    #
    # @return [Hash]
    #
    def cheffish_details
      load_server_config
      {
        chef_server_url: Chef::Config[:chef_server_url],
        options: {
          client_name: Chef::Config[:node_name],
          signing_key_filename: Chef::Config[:client_key]
        }
      }
    ensure
      unload_server_config
    end

    private

    #
    # Save away the current Chef::Config and load the one for the Chef Server.
    #
    def load_server_config
      @stored_config = Chef::Config.save
      Chef::Config.restore(@server_config)
    end

    #
    # Return the path to the configured data bag secret
    #
    # @return [String]
    #
    def secret_key_file
      Chef::Config[:encrypted_data_bag_secret]
    end

    #
    # Reload whatever Chef::Config was being used before communication with this
    # Chef Server was established.
    #
    def unload_server_config
      Chef::Config.restore(@stored_config)
    end

    #
    # The default path for the Chef Config file to use with the Delivery Chef
    # Server.
    #
    # @return [String]
    #
    def delivery_knife_rb
      '/var/opt/delivery/workspace/.chef/knife.rb'
    end
  end
end
