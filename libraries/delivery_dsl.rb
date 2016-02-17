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
  module DSL
    #
    # The path for the Chef Config file to use with the Delivery Chef Server.
    #
    # @return [String]
    #
    def delivery_knife_rb
      File.join(delivery_workspace, '.chef/knife.rb')
    end

    #
    # The workspace path on the build nodes
    #
    # @return [String]
    #
    def delivery_workspace
      change.workspace_path
    rescue
      '/var/opt/delivery/workspace'
    end

    #
    # The repository path inside the workspace for the current project
    #
    # @return [String]
    #
    def delivery_workspace_repo
      change.workspace_repo
    end

    #
    # The chef path inside the workspace for the current project
    #
    # @return [String]
    #
    def delivery_workspace_chef
      change.workspace_chef
    end

    #
    # The cache path inside the workspace for the current project
    #
    # @return [String]
    #
    def delivery_workspace_cache
      change.workspace_cache
    end

    #
    # The change id
    #
    # @return [String]
    #
    def delivery_change_id
      change.change_id
    end

    #
    # The project
    #
    # @return [String]
    #
    def delivery_project
      change.project
    end

    #
    # Return a list of cookbooks that have files that have changed in the current
    # changeset.
    #
    # @return [Array<String>]
    #
    def changed_cookbooks
      change.changed_cookbooks
    end

    #
    # Return a list of filenames (relative to the project root) that have been
    # modified in the current changeset.

    # @return [Array<String>]
    #
    def changed_files
      change.changed_files
    end

    #
    # Return the name of the Chef environment that corresponds with the stage
    # for the current phase run.
    #
    # @return [String]
    #
    def delivery_environment
      change.environment_for_current_stage
    end

    #
    # Return the name of the acceptance environment associated with the current
    # changesets pipeline.
    #
    # @return [String]
    #
    # Rubocop disabled because this is established API
    # rubocop:disable AccessorMethodName
    def get_acceptance_environment
      change.acceptance_environment
    end

    #
    # Return the decrypted contents of an encrypted data bag on the Chef Server
    # that holds secret data related to the current project.
    #
    # @return [Hash]
    #
    def get_project_secrets
      chef_server.encrypted_data_bag_item('delivery-secrets', project_slug)
    rescue Net::HTTPServerException => http_e
      raise http_e unless http_e.response.code == '404'
      Chef::Log.warn("Secrets Not Found for project_slug[#{project_slug}]")
      Chef::Log.info("Loading organization secrets #{organization_slug}")
      get_organization_secrets
    end

    #
    # Return the decrypted contents of an encrypted data bag on the Chef Server
    # that holds secret data related to the current organization.
    #
    # @return [Hash]
    #
    def get_organization_secrets
      chef_server.encrypted_data_bag_item('delivery-secrets', organization_slug)
    end

    #
    # Return a unique string that can be used to identify the current project.
    #
    # @return [String]
    #
    def project_slug
      change.project_slug
    end

    #
    # Return a unique string that can be used to identify the current organization
    #
    # @return [String]
    #
    def organization_slug
      change.organization_slug
    end

    #
    # Return an array of paths for valid cookbooks for this change,
    # based on metadata.rb/json
    # The root directory, or cookbooks in the /cookbooks directory will be returned
    #
    # @return [Array<String>]
    #
    def get_all_project_cookbooks
      change.get_all_project_cookbooks
    end

    #
    # Define a project application, upload it as a data bag item,
    # and set its version pin for the acceptance env for a change.
    #
    # @param [String] app_name
    #   A string representing your application's name
    # @param [String] app_version
    #   A string representing your application's version
    # @param [Hash] app_attributes
    #   A hash of attributes that make up your application at app_version.
    #   Should contain key, strings, and arrays.
    #
    # @return [Chef::Environment]
    #
    def define_project_application(app_name, app_version, app_attributes)
      change.define_project_application(app_name, app_version, app_attributes)
    end

    #
    # Load a project application's attributes previously
    # defined by define_project_application(). Will be
    # loaded at the current version pin for environment (must be
    # in acceptance, union, rehearsal, or delivered stage).
    #
    # @param [String] app_name
    #   A string representing your application's name
    #
    # @return [Chef::Environment]
    #
    def get_project_application(app_name)
      change.get_project_application(app_name)
    end

    #
    # Return a hash with the details that Cheffish resources require to talk to
    # the delivery Chef Server.
    #
    # @return [Hash]
    #
    def delivery_chef_server
      chef_server.cheffish_details
    end

    #
    # Expose the server config block to do certain tasks like:
    #
    # with_server_config do
    #   load_secret_item = encrypted_data_bag_item_for_environment('creds', 'secret')
    # end
    #
    def with_server_config(&block)
      chef_server.with_server_config(&block)
    end

    #
    # Expose the server config block for the entire recipe (never leaving)
    #
    def load_delivery_chef_config
      chef_server.load_server_config
    end

    private

    #
    # Return a Chef Server object pointing to the Delivery Chef Server
    #
    # @return [DeliverySugar::ChefServer]
    #
    def chef_server
      @delivery_chef_server ||= DeliverySugar::ChefServer.new
    end

    #
    # Return a Change object for the current change
    #
    # @return [DeliverySugar::Change]
    #
    def change
      @change ||= DeliverySugar::Change.new(node)
    end
  end
end
