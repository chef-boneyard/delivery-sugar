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
      def initialize(new_resource, run_context)
        super
        @failures = []
      end

      def whyrun_supported?
        true
      end

      def load_current_resource
        # There is no existing resource to evaluate, but we are required
        # to override it.
      end

      def action_upload
        converge_by "Upload cookbook #{new_resource.cookbook_to_upload} to " \
                    "#{chef_server_list}" do
          upload_cookbook_to_chef_servers
          new_resource.updated_by_last_action(at_least_one_successful_upload?)
          raise_if_an_upload_failed!
        end
      end

      private

      #
      # Return the list of Chef Servers as an array
      #
      # @return [Array<String>]
      #
      def chef_servers
        [*new_resource.chef_server]
      end

      #
      # Return if at least one upload was successful. We'll use this to determine
      # if the resource was "updated".
      #
      # @return [TrueClass, FalseClass]
      #
      def at_least_one_successful_upload?
        @failures.length != chef_servers.length
      end

      #
      # Upload the cookbook to the specified Chef Server(s). If the upload fails,
      # log that failure
      #
      def upload_cookbook_to_chef_servers
        chef_servers.each do |server|
          begin
            upload_cookbook(server)
          rescue Mixlib::ShellOut::ShellCommandFailed => e
            @failures << server.to_s
            Chef::Log.error(e.message)
          end
        end
      end

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
          new_resource.cookbook_to_upload,
          new_resource.path
        )
        result.error!
      end

      #
      # If at least one upload failed, raise an error.
      #
      # @raise [DeliverySugar::Exceptions::CookbookUploadFailed]
      #
      def raise_if_an_upload_failed!
        return if @failures.empty?
        fail DeliverySugar::Exceptions::CookbookUploadFailed.new(
          new_resource.cookbook_to_upload,
          @failures
        )
      end

      #
      # Print out the list of chef server's we're uploading to in a pretty,
      # comma-delimited list.
      #
      # @return [String]
      #
      def chef_server_list
        chef_servers.map(&:to_s).join(', ')
      end
    end
  end
end
