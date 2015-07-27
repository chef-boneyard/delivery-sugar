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

require 'chef/resource'

class Chef
  class Resource
    class DeliveryChefCookbook < Chef::Resource
      provides :delivery_chef_cookbook

      def initialize(name, run_context = nil)
        super

        @resource_name = :delivery_chef_cookbook
        @cookbook_to_upload = name

        @provider = Chef::Provider::DeliveryChefCookbook
        @action = :upload
        @allowed_actions.push(:upload)
      end

      def cookbook_to_upload(arg = nil)
        set_or_return(
          :cookbook_to_upload,
          arg,
          kind_of: String
        )
      end

      def path(arg = nil)
        set_or_return(
          :path,
          arg,
          kind_of: String, required: true
        )
      end

      def chef_server(arg = nil)
        set_or_return(
          :chef_server,
          arg,
          kind_of: [Array, DeliverySugar::ChefServer], required: true
        )
      end
    end
  end
end
