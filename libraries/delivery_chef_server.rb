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

require 'chef/mixin/shell_out'
require 'chef/server_api'
require_relative './delivery_dsl'

# (afiune) TODO: We should be able to put `gem 'chef-vault'` in the `metadata.rb` but
# that is breaking air-gapped environments because is trying to reach out to rubygems.org
# the solution is to add an option to the `automate-ctl install-runner` command that sets
# up the `Chef::Config[:rubygems_url]` to the users rubygem internal mirror.
begin
  require 'chef-vault'
rescue LoadError
  Chef::Log.debug("could not load chef-vault whilst loading #{__FILE__}, if this is")
  Chef::Log.debug('an air-gapped environment, make sure you have the latest chefdk ')
  Chef::Log.debug('version. Otherwise make sure the chef-vault gem is installed')
end

module DeliverySugar
  #
  # This is class we will use to interface with Chef Servers.
  #
  class ChefServer
    include Chef::Mixin::ShellOut
    include DeliverySugar::DSL
    attr_reader :server_config, :stored_config, :knife_rb

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
      @knife_rb = chef_config_rb
      Chef::Config.from_file(@knife_rb)
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
    # A more general purpose data bag collector. Can handle both encrypted
    # and non-encrypted data bags.
    #
    # @param bag_name [String]
    #   The name of the data bag
    # @param item_id [String]
    #   The name of the data bag item
    # @param secret_file [String]
    #   The path to the non-standard encryption secret file
    #
    # @return [Hash]
    #
    def data_bag_item(bag_name, item_id, file = nil)
      with_server_config do
        secret = file.nil? ? nil : Chef::EncryptedDataBagItem.load_secret(file)
        data_query.data_bag_item(bag_name, item_id, secret)
      end
    end

    #
    # Return the decrypted contents of a Chef Vault from the Chef Server.
    #
    # @param vault_name [String]
    #   The name of the Chef Vault
    # @param item_id [String]
    #   The name of the vault item
    #
    # @return [Hash]
    #
    def chef_vault_item(vault_name, item_id)
      with_server_config do
        ChefVault::Item.load(vault_name, item_id)
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
    # Run the block with the @server_config Chef::Config global scope.
    #
    def with_server_config(&block)
      load_server_config
      yield block
    ensure
      unload_server_config
    end

    #
    # Make a JSON ServerAPI call to the Chef Server using Chef::ServerAPI. Returns the
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
      with_server_config do
        rest_client.request(type, path, headers, data)
      end
    end

    #
    # Execute a knife command against the Chef Server. Returns the Mixlib::ShellOut
    # object.
    #
    # @param cmd [String]
    #   The knife subcommand that we want to run.
    #
    # @return [Mixlib::ShellOut]
    #
    def knife_command(cmd)
      shell_out("knife #{cmd} --config #{knife_rb}")
    end

    #
    # Upload a cookbook to this Chef Server.
    #
    # @param name [String]
    #   The name of the cookbook.
    #
    # @param path [String]
    #   The path to the cookbook on disk.
    #
    # @return
    #
    def upload_cookbook(name, path)
      cookbook_path = ::File.dirname(path)
      knife_command("cookbook upload #{name} --cookbook-path #{cookbook_path}")
    end

    #
    # Return a brief representation of this class as a String
    #
    # @return [String]
    #
    def to_s
      "#{@server_config[:node_name]}@#{@server_config[:chef_server_url]}"
    end

    #
    # Save away the current Chef::Config and load the one for the Chef Server.
    #
    def load_server_config
      @stored_config = Chef::Config.save
      Chef::Config.reset
      Chef::Config.restore(@server_config)
    end

    #
    # Reload whatever Chef::Config was being used before communication with this
    # Chef Server was established.
    #
    def unload_server_config
      Chef::Config.reset
      Chef::Config.restore(@stored_config)
    end

    private

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
    # A ServerAPI client we can use to submit API requests to APIs on the Chef Server
    #
    # @return [Chef::ServerAPI]
    #
    def rest_client
      @rest_client ||= Chef::ServerAPI.new(
        @server_config[:chef_server_url],
        client_name: @server_config[:node_name],
        signing_key_filename: @server_config[:client_key]
      )
    end

    #
    # A wrapper for the DataQuery functionality of core Chef. This allows us
    # to do some cool things like have the helper handle either encrypted or
    # normal data bag items.
    #
    def data_query
      @data_query ||= Object.new.extend(Chef::DSL::DataQuery)
    end
  end
end
