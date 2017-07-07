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
  # rubocop:disable Metrics/ModuleLength
  module DSL
    #
    # The name of the build user
    #
    # @return [String]
    #
    def build_user
      change.build_user
    end

    #
    # The path for the Chef Config file to use with the Automate Chef Server.
    #
    # @return [String]
    #
    def delivery_knife_rb
      File.join(delivery_workspace, '.chef/knife.rb')
    end
    alias_method :automate_knife_rb, :delivery_knife_rb

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
    alias_method :workflow_workspace, :delivery_workspace

    #
    # The repository path inside the workspace for the current project
    #
    # @return [String]
    #
    def delivery_workspace_repo
      change.workspace_repo
    end
    alias_method :workflow_workspace_repo, :delivery_workspace_repo

    #
    # The chef path inside the workspace for the current project
    #
    # @return [String]
    #
    def delivery_workspace_chef
      change.workspace_chef
    end
    alias_method :workflow_workspace_chef, :delivery_workspace_chef

    #
    # The cache path inside the workspace for the current project
    #
    # @return [String]
    #
    def delivery_workspace_cache
      change.workspace_cache
    end
    alias_method :workflow_workspace_cache, :delivery_workspace_cache

    #
    # The root of the workspace path for the change
    #
    # @return [String]
    #
    def workflow_workspace_root
      change.workspace_root
    end

    #
    # The change id
    #
    # @return [String]
    #
    def delivery_change_id
      change.change_id
    end
    alias_method :workflow_change_id, :delivery_change_id

    #
    # The merge sha associated with the change
    #
    # @return [String]
    #
    def workflow_change_merge_sha
      change.merge_sha
    end

    #
    # Return the name of the enterprise associated with the change
    #
    # @return [String]
    #
    def workflow_change_enterprise
      change.enterprise
    end

    #
    # Return the name of the organization associated with the change
    #
    # @return [String]
    #
    def workflow_change_organization
      change.organization
    end

    #
    # Return the name of the project associated with the change
    #
    # @return [String]
    #
    def delivery_project
      change.project
    end
    alias_method :workflow_change_project, :delivery_project

    #
    # Return the name of the pipeline associated with the change
    #
    # @return [String]
    #
    def workflow_change_pipeline
      change.pipeline
    end

    #
    # Return the name of the patchset branch associated with the change
    #
    # @return [String]
    #
    def workflow_change_patchset_branch
      change.patchset_branch
    end

    #
    # Return a list of cookbooks that have files that have changed in the current
    # changeset.
    #
    # @return [Array<DeliverySugar::Cookbook>]
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
    # Return a list of directories (relative to the project root) that have been
    # modified in the current changeset.
    #
    # @return [Array<String>]
    #
    def changed_dirs(depth = nil)
      change.changed_dirs(depth)
    end

    #
    # Return a list of commit log entries in reverse chronological order.
    #
    # @return [Array<String>]
    def change_log
      change.change_log
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
    alias_method :workflow_chef_environment_for_stage, :delivery_environment

    #
    # Return the name of the Stage for the current job
    #
    # @return [String]
    #
    def workflow_stage
      change.stage
    end

    #
    # Return whether or not the current stage matches the given stage
    #
    # @return [TrueClass, FalseClass]
    #
    def workflow_stage?(stage)
      change.stage == stage
    end

    #
    # Return the name of the Phase for the current job
    #
    # @return [String]
    #
    def workflow_phase
      change.phase
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
    alias_method :workflow_project_acceptance_environment, :get_acceptance_environment

    #
    # Return the (decrypted) contents of the specified data bag item
    #
    # @return [Hash]
    #
    def get_secrets(bag, item, secret_file = nil)
      automate_chef_server.data_bag_item(bag, item, secret_file)
    end

    #
    # Return the decrypted contents of an encrypted data bag on the Chef Server
    # that holds secret data related to the current project.
    #
    # @return [Hash]
    #
    def get_project_secrets
      get_secrets('delivery-secrets', project_slug)
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
      get_secrets('delivery-secrets', organization_slug)
    end

    #
    # Return the decrypted contents of a Chef Vault on the Chef Server
    #
    # @return [Hash]
    #
    def get_chef_vault(vault, item_id)
      automate_chef_server.chef_vault_item(vault, item_id)
    end

    #
    # Return a list of decrypted Chef Vault data from the Chef Server
    #
    # @return [List]
    def get_chef_vault_data_list
      list = []
      [enterprise_slug, organization_slug, project_slug].each do |slug|
        begin
          list.push(get_chef_vault('workflow-vaults', slug))
        rescue ChefVault::Exceptions::KeysNotFound
          list.push({})
        end
      end
      list
    end

    #
    # Return the decrypted contents of Chef Vaults under `workflow-vaults`
    # on the Chef Server that hold data related to Workflow
    #
    # @return [Hash]
    #
    def get_chef_vault_data
      get_chef_vault_data_list.inject(&:merge)
    end
    alias_method :get_workflow_vault_data, :get_chef_vault_data

    #
    # Return a unique string that can be used to identify the current enterprise
    #
    # @return [String]
    #
    def enterprise_slug
      change.enterprise_slug
    end
    alias_method :workflow_enterprise_slug, :enterprise_slug

    #
    # Return a unique string that can be used to identify the current project.
    #
    # @return [String]
    #
    def project_slug
      change.project_slug
    end
    alias_method :workflow_project_slug, :project_slug

    #
    # Return a unique string that can be used to identify the current organization
    #
    # @return [String]
    #
    def organization_slug
      change.organization_slug
    end
    alias_method :workflow_organization_slug, :organization_slug

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
    # Must be run in the build phase.
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
    def define_project_application(app_name, app_version, app_attributes = {})
      change.define_project_application(app_name, app_version, app_attributes)
    end
    alias_method :create_workflow_application_release, :define_project_application

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
    alias_method :get_workflow_application_release, :get_project_application

    #
    # Return a hash with the details that Cheffish resources require to talk to
    # the delivery Chef Server.
    #
    # @return [Hash]
    #
    def delivery_chef_server
      automate_chef_server.cheffish_details
    end
    alias_method :automate_chef_server_details, :delivery_chef_server

    #
    # Expose the server config block to do certain tasks like:
    #
    # with_server_config do
    #   load_secret_item = encrypted_data_bag_item_for_environment('creds', 'secret')
    # end
    #
    def with_server_config(&block)
      automate_chef_server.with_server_config(&block)
    end

    #
    # Expose the server config block for the entire recipe (never leaving)
    #
    def load_delivery_chef_config
      automate_chef_server.load_server_config
    end
    alias_method :run_recipe_against_automate_chef_server, :load_delivery_chef_config

    private

    #
    # Return a Chef Server object pointing to the Delivery Chef Server
    #
    # @return [DeliverySugar::ChefServer]
    #
    def automate_chef_server
      @automate_chef_server ||= DeliverySugar::ChefServer.new(delivery_knife_rb)
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
