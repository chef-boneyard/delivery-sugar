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
require_relative './delivery_dsl'
require 'chef/dsl'

module DeliverySugar
  #
  # This class is our interface to execute test kitchen in Delivery
  #
  # We are disabling the ClassLength cop for now, but we will want to refactor
  # this to be cleaner in the future.
  #
  # rubocop:disable ClassLength
  class TestKitchen
    include Chef::DSL::Recipe
    include DeliverySugar::DSL
    include Chef::Mixin::ShellOut
    attr_reader :driver, :repo_path, :environment, :options
    attr_accessor :suite, :timeout, :yaml, :run_context

    #
    # Create a new TestKitchen object
    #
    # @param driver [String]
    #   The test kitchen driver
    # @param repo_path [String]
    #   The path to the project repository within the workspace
    # @param run_context [Chef::RunContext]
    #   The object that loads and tracks the context of the Chef run
    # @param yaml [String]
    #   The name of the Kitchen YAML file
    #
    # @return [DeliverySugar::TestKitchen]
    #
    def initialize(driver, repo_path, run_context, parameters = {})
      @driver = driver
      @repo_path = repo_path
      @run_context = run_context
      @yaml = parameters[:yaml]
      @suite = parameters[:suite]
      @options = parameters[:options] || ''
      @environment = parameters[:environment] || {}
      @timeout = parameters[:timeout]
    end

    #
    # Run test kitchen action
    #
    def run(action)
      prepare_kitchen
      shell_out!(
        "kitchen #{action} #{suite} #{@options}",
        cwd: @repo_path,
        env: @environment.merge!('KITCHEN_YAML' => kitchen_yaml_file),
        live_stream: STDOUT,
        timeout: @timeout
      )
    end

    #
    # Add extra options
    #
    def add_option(n_option)
      @options << ' ' << n_option
    end

    private

    #
    # Prepare the kitchen with specific driver configuration
    #
    # rubocop:disable Metrics/MethodLength
    def prepare_kitchen
      case @driver
      when 'ec2'
        prepare_kitchen_ec2
      when 'dokken'
        prepare_kitchen_dokken
      when 'azurerm'
        prepare_kitchen_azurerm
      when 'vsphere'
        prepare_kitchen_vsphere
      else
        fail "The test kitchen driver '#{@driver}' is not supported"
      end
    end

    #
    # Specific requirements for EC2 driver
    #
    # rubocop:disable AbcSize
    def prepare_kitchen_ec2
      fail 'Kitchen YAML file not found' unless kitchen_yaml?

      # Load secrets from delivery-secrets data bag
      secrets = get_project_secrets
      msg = 'Could not find secrets for kitchen-ec2 driver ' \
            'in delivery-secrets data bag.'
      fail msg if secrets['ec2'].nil?

      # Variables used for configuring and running test kitchen EC2
      cache                 = delivery_workspace_cache
      ec2_keypair_name      = secrets['ec2']['keypair_name']
      ec2_private_key_file  = "#{cache}/.ssh/#{ec2_keypair_name}.pem"
      kitchen_instance_name = "test-kitchen-#{delivery_project}-#{delivery_change_id}"

      @environment.merge!(
        'AWS_SSH_KEY_ID'            => ec2_keypair_name,
        'KITCHEN_EC2_SSH_KEY_PATH'  => ec2_private_key_file,
        'KITCHEN_INSTANCE_NAME'     => kitchen_instance_name,
        'AWS_ACCESS_KEY_ID'         => secrets['ec2']['access_key'],
        'AWS_SECRET_ACCESS_KEY'     => secrets['ec2']['secret_key']
      )

      # Installing kitchen-ec2 driver
      chef_gem = Chef::Resource::ChefGem.new('kitchen-ec2', run_context)
      chef_gem.run_action(:install)

      # Create directories for AWS credentials and SSH key
      %w(.aws .ssh).each do |d|
        directory = Chef::Resource::Directory.new(File.join(cache, d), run_context)
        directory.recursive true
        directory.run_action(:create)
      end

      # Create AWS credentials file
      file = Chef::Resource::File.new("#{cache}/.aws/credentials", run_context).tap do |f|
        f.sensitive true
        f.content <<-EOF
[default]
aws_access_key_id = #{secrets['ec2']['access_key']}
aws_secret_access_key = #{secrets['ec2']['secret_key']}
        EOF
      end
      file.run_action(:create)

      # Create private key
      file = Chef::Resource::File.new(ec2_private_key_file, run_context).tap do |f|
        f.content secrets['ec2']['private_key']
        f.sensitive true
        f.mode '0400'
      end
      file.run_action(:create)
    end
    #
    # Specific requirements for dokken driver
    # At this point, we might not really need to do very much because there
    # isn't a lot of prep to do for this driver.
    #

    def prepare_kitchen_dokken
      fail 'Kitchen YAML file not found' unless kitchen_yaml?

      # Installing kitchen-dokken driver
      chef_gem = Chef::Resource::ChefGem.new('kitchen-dokken', run_context)
      chef_gem.run_action(:install)
    end

    #
    # Specific requirements for azurerm driver
    #
    def prepare_kitchen_azurerm
      fail 'Kitchen YAML file not found' unless kitchen_yaml?

      # Load secrets from delivery-secrets data bag
      secrets = get_project_secrets
      msg = 'Could not find secrets for kitchen-azurerm driver ' \
            'in delivery-secrets data bag.'
      fail msg if secrets['azurerm'].nil?

      # Variables used for configuring and running test kitchen Azure
      cache                 = delivery_workspace_cache
      azure_subscription_id = secrets['azurerm']['subscription_id']
      azure_client_id       = secrets['azurerm']['client_id']
      azure_client_secret   = secrets['azurerm']['client_secret']
      azure_tenant_id       = secrets['azurerm']['tenant_id']
      kitchen_instance_name = "test-kitchen-#{delivery_project}-#{delivery_change_id}"

      @environment.merge!(
        'AZURE_CLIENT_ID'            => azure_client_id,
        'AZURE_CLIENT_SECRET'        => azure_client_secret,
        'AZURE_TENANT_ID'            => azure_tenant_id,
        'KITCHEN_INSTANCE_NAME'      => kitchen_instance_name
      )

      # Installing kitchen-azurerm driver
      begin
        chef_gem = Chef::Resource::ChefGem.new('kitchen-azurerm', run_context)
        chef_gem.run_action(:install)
      rescue => e
        Chef::Log.error('Azure gem installation failed. \
        You might need to ensure that dev tools are installed.')
        Chef::Log.error("Add depends 'build-essential' to \
        the metadata.rb of your build cookbook and add include_recipe \
        'build-essential' to the default.rb of your build cookbook")
        raise e.message
      end

      # Create directories for Azure credentials and SSH key
      %w(.azure .ssh).each do |d|
        directory = Chef::Resource::Directory.new(File.join(cache, d), run_context)
        directory.recursive true
        directory.run_action(:create)
      end

      # Create Azure credentials file
      azure_creds_path = "#{cache}/.azure/credentials"
      file = Chef::Resource::File.new(azure_creds_path, run_context).tap do |f|
        f.sensitive true
        f.content <<-EOF
  [#{azure_subscription_id}]
  client_id = #{secrets['azurerm']['client_id']}
  client_secret = #{secrets['azurerm']['client_secret']}
  tenant_id = #{secrets['azurerm']['tenant_id']}
      EOF
      end
      file.run_action(:create)
    end

    #
    # Specific requirements for Vsphere driver
    #
    def prepare_kitchen_vsphere
      fail 'Kitchen YAML file not found' unless kitchen_yaml?

      # Load secrets from delivery-secrets data bag
      secrets = get_project_secrets
      msg = 'Could not find secrets for kitchen-vsphere driver ' \
            'in delivery-secrets data bag.'
      fail msg if secrets['vsphere'].nil?

      # Variables used for configuring and running test kitchen Vsphere
      kitchen_instance_name = "test-kitchen-#{delivery_project}-#{delivery_change_id}"
      insecure              = secrets['vsphere']['insecure'] || true

      @environment.merge!(
        'VSPHERE_HOST'              => secrets['vsphere']['host'],
        'VSPHERE_USER'              => secrets['vsphere']['user'],
        'VSPHERE_PASSWORD'          => secrets['vsphere']['password'],
        'VSPHERE_CONN_INSECURE'     => insecure,
        'KITCHEN_INSTANCE_NAME'     => kitchen_instance_name
      )

      # Installing kitchen-vsphere driver
      chef_gem = Chef::Resource::ChefGem.new('chef-provisioning-vsphere', run_context)
      chef_gem.run_action(:install)
    end

    # See if the kitchen YAML file exist in the repo
    #
    # @return [TrueClass, FalseClass] Return true if file exists
    def kitchen_yaml?
      ::File.exist?(kitchen_yaml_file)
    end

    # Return file system path to the kitchen YAML file
    #
    # @return [String] String representing full path to kitchen YAML file in the repo
    def kitchen_yaml_file
      ::File.join(@repo_path, @yaml)
    end

    # Returns the Chef::Node Object coming from the run_context
    def node
      run_context && run_context.node
    end

    # Used by providers supporting embedded recipes
    def resource_collection
      run_context && run_context.resource_collection
    end
  end
end
