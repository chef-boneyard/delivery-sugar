#
# Copyright:: Copyright (c) 2016 Chef Software, Inc.
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
    class DeliverySupermarket < Chef::Provider
      include Chef::Mixin::ShellOut

      def whyrun_supported?
        true
      end

      def load_current_resource
        # If they provide the cookbook_path we will get the parent dir
        parent_path = ::File.expand_path('..', new_resource.path)
        new_resource.path(parent_path)
      end

      # rubocop:disable MethodLength
      def action_share
        converge_by "Share #{new_resource.cookbook} cookbook to #{new_resource.site}" do
          if verify_cookbook_version_in_supermarket
            new_resource.updated_by_last_action(false)
            return
          end
          options = ''
          options = "-k #{supermarket_tmp_key_path}" if create_supermarket_key
          share_cookbook_to_supermarket(options)
          remove_supermarket_key
          new_resource.updated_by_last_action(true)
        end
      end

      private

      # Write the Supermarket key to a file on disk
      def create_supermarket_key
        return false if new_resource.key.nil?
        f = ::File.new(supermarket_tmp_key_path, 'w+')
        f.write(new_resource.key)
        f.close
        true
      end

      # Remove the Supermarket key from disk
      def remove_supermarket_key
        return if new_resource.key.nil?
        ::File.delete(supermarket_tmp_key_path)
      end

      # Share the cookbook to the Supermarket Site
      def share_cookbook_to_supermarket(options)
        command = "knife supermarket share #{new_resource.cookbook} " \
                  "--cookbook-path #{new_resource.path} " \
                  "--config #{new_resource.config} " \
                  "--supermarket-site #{new_resource.site} " \
                  "-u #{new_resource.user} " \
                  "#{options}"
        shell_out!(command)
      end

      def verify_cookbook_version_in_supermarket
        command = "knife supermarket show #{new_resource.cookbook} " \
                  "#{new_resource.cookbook_version} " \
                  "--config #{new_resource.config} " \
                  "--supermarket-site #{new_resource.site}"
        output = shell_out(command)

        # If we can show the cookbook::version, means it already exists
        output.exitstatus == 0 ? true : false
      end

      def supermarket_tmp_key_path
        @supermarket_tmp_key_path ||= ::File.join(
          delivery_workspace_cache,
          'supermarket.pem'
        )
      end
    end
  end
end
