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

require 'chef/provider'

class Chef
  class Provider
    class DeliveryChefCookbook < Chef::Provider
      def whyrun_supported?
        true
      end

      def load_current_resource
        # There is no existing resource to evaluate, but we are required
        # to override it.
      end

      def action_upload
        converge_by "Upload cookbook #{new_resource.cookbook_name} to " \
                    "#{new_resource.chef_server}" do
          upload_cookbook(new_resource.chef_server)
          new_resource.updated_by_last_action(true)
        end
      end

      private

      #
      # Upload the cookbook to the specified Chef Server
      #
      # @param chef_server [DeliverySugar::ChefServer]
      #
      # @return [NilClass]
      #   Mixlib::ShellOut#error! returns nil if it does not raise
      #
      # @raise [ShellCommandFailed]
      #   If the knife command fails, a ShellCommandFailed will occur
      def upload_cookbook(chef_server)
        result = chef_server.upload_cookbook(
          new_resource.cookbook_name,
          new_resource.path
        )
        result.error!
      end
    end
  end
end
