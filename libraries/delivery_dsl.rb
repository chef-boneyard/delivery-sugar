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
    def changed_cookbooks
      change.changed_cookbooks
    end

    def changed_files
      change.changed_files
    end

    def delivery_environment
      change.environment_for_current_stage
    end

    # Rubocop disabled because this is established API
    # rubocop:disable AccessorMethodName
    def get_acceptance_environment
      change.acceptance_environment
    end

    def get_project_secrets
      chef_server.encrypted_data_bag_item('delivery-secrets', project_slug)
    end

    def project_slug
      change.project_slug
    end

    def delivery_chef_server
      chef_server.cheffish_details
    end

    private

    def chef_server
      @delivery_chef_server ||= DeliverySugar::ChefServer.new(delivery_knife_rb)
    end

    def change
      @change ||= DeliverySugar::Change.new(node)
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
