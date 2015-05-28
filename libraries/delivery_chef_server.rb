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
      Chef::Config.reset
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
    def encrypted_data_bag_item(bag_name, item_id, secret_key = secret_key_file)
      with_server_config do
        secret_file = Chef::EncryptedDataBagItem.load_secret(secret_key)
        Chef::EncryptedDataBagItem.load(bag_name, item_id, secret_file)
      end
    end

    #
    # Return a hash that can be fed into Cheffish resources.
    #
    # @return [Hash]
    #
    def cheffish_details
      {
        chef_server_url: @server_config[:chef_server_url],
        options: {
          client_name: @server_config[:node_name],
          signing_key_filename: @server_config[:client_key]
        }
      }
    end

    #
    # Make a JSON REST API call to the Chef Server using Chef::REST. Returns the
    # the JSON response data as a Ruby Hash.
    #
    # @param type [Symbol]
    #   The request type. Valid types are :GET, :POST, :PUT, :DELETE. Validation
    #   of those types is handled by the request method.
    #
    # @param path [String]
    #   The API path to hit relative to the chef_server_url.
    #
    # @param headers [Hash]
    #   The headers to pass in to the request. By default this is an empty Hash.
    #
    # @param data [Hash, FalseClass]
    #    Data to pass into the request. When making GET/DELETE requests this
    #    should be false. When making PUT/POST requests, this should be a Hash
    #    that represents a JSON object.
    #
    # @return [Hash]
    #
    def rest(type, path, headers = {}, data = false)
      rest_client.request(type, path, headers, data)
    end

    #
    # Run the block with the @server_config Chef::Config global scope.
    #
    def with_server_config(&block)
      load_server_config
      block.call
    ensure
      unload_server_config
    end

    #
    # Make a JSON REST API call to the Chef Server using Chef::REST. Returns the
    # the JSON response data as a Ruby Hash.
    #
    # @param type [Symbol]
    #   The request type. Valid types are :GET, :POST, :PUT, :DELETE. Validation
    #   of those types is handled by the request method.
    #
    # @param path [String]
    #   The API path to hit relative to the chef_server_url.
    #
    # @param headers [Hash]
    #   The headers to pass in to the request. By default this is an empty Hash.
    #
    # @param data [Hash, FalseClass]
    #    Data to pass into the request. When making GET/DELETE requests this
    #    should be false. When making PUT/POST requests, this should be a Hash
    #    that represents a JSON object.
    #
    # @return [Hash]
    #
    def rest(type, path, headers = {}, data = false)
      rest_client.request(type, path, headers, data)
    end

    private

    #
    # Save away the current Chef::Config and load the one for the Chef Server.
    #
    def load_server_config
      @stored_config = Chef::Config.save
      Chef::Config.reset
      Chef::Config.restore(@server_config)
    end

    #
    # Return the path to the configured data bag secret. We don't use @server_config
    # here because the encrypted_data_bag_secret value isn't part of the default
    # chef config files we use. As such we must load the config and rely on
    # Chef::Config to find it for us.
    #
    # @return [String]
    #
    def secret_key_file
      with_server_config do
        Chef::Config[:encrypted_data_bag_secret]
      end
    end

    #
    # Reload whatever Chef::Config was being used before communication with this
    # Chef Server was established.
    #
    def unload_server_config
      Chef::Config.reset
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

    #
    # A REST client we can use to submit API requests to APIs on the Chef Server
    #
    # @return [Chef::Rest]
    #
    def rest_client
      @rest_client ||= Chef::REST.new(
        @server_config[:chef_server_url],
        @server_config[:node_name],
        @server_config[:client_key]
      )
    end
  end
end
