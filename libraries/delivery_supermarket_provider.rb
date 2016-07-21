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
        # There is no existing resource to evaluate, but we are required
        # to override it.
      end

      def action_share
        converge_by "Share #{new_resource.name} cookbook to #{new_resource.site}" do
          options = "" 
          key_path = create_supermarket_key
          options += "-k #{key_path}" unless key_path.nil?
          share_cookbook_to_supermarket(options)
          new_resource.updated_by_last_action(true)
        end
      end

      private

      # Write the Supermarket key to a file on disk
      def create_supermarket_key
        return nil if new_resource.key.nil?
        supermarket_tmp_key_path = File.join(delivery_workspace_cache, "supermarket.pem")
        f = File.new(supermarket_tmp_key_path, "w+")
        f.write(new_resource.key)
        f.close
        return supermarket_tmp_key_path
      end

      def share_coookbook_to_supermarket(options)
        execute "share_cookbook_to_supermarket_#{new_resource.cookbook_name}" do
          command "knife supermarket share #{new_resource.cookbook_name} " \
                  "--cookbook-path #{new_resource.cookbook_path} " \
                  "--config #{new_resource.config} " \
                  "--supermarket-site #{new_resource.site} " \
                  "-u #{new_resource.user} " \
                  "#{options}"
          not_if "knife supermarket show #{cookbook.name} #{cookbook.version} " \
                  "--config #{delivery_knife_rb} " \
                  "--supermarket-site #{supermarket_site}"
        end
      end
    end
  end
end
