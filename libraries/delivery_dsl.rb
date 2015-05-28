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
    # Return a list of cookbooks that have files that have changed in the current
    # changeset.
    #
    # @return [Array#String]
    #
    def changed_cookbooks
      change.changed_cookbooks
    end

    #
    # Return a list of filenames (relative to the project root) that have been
    # modified in the current changeset.
    #
    # @return [Array#String]
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
    # Return a hash with the details that Cheffish resources require to talk to
    # the delivery Chef Server.
    #
    # @return [Hash]
    #
    def delivery_chef_server
      chef_server.cheffish_details
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
