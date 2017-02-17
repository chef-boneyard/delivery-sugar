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
require_relative './delivery_dsl'

class DeliverySupermarket < Chef::Resource
  include DeliverySugar::DSL
  resource_name :delivery_supermarket

  # The cookbook object
  def sugar_cookbook
    DeliverySugar::Cookbook.new(path)
  end

  property :path, String, default: lazy { delivery_workspace_repo }
  property :cookbook, String, default: lazy { sugar_cookbook.name }
  property :version, String, default: lazy { sugar_cookbook.version }

  # The knife.rb config file on disk
  property :config, String, default: lazy { delivery_knife_rb }

  # The Supermarket site / user / category / key
  property :site, String, default: 'https://supermarket.chef.io'
  property :user, String, default: 'delivery'
  property :category, String, default: 'Other'
  property :key, String

  action :share do
    unless cookbook_version_in_supermarket
      converge_by "Share #{new_resource.cookbook} cookbook to #{new_resource.site}" do
        options = create_supermarket_key ? "-k #{supermarket_tmp_key_path}" : ''
        share_cookbook_to_supermarket(options)
        remove_supermarket_key
      end
    end
  end

  action_class do
    include Chef::Mixin::ShellOut

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
                "\"#{new_resource.category}\" " \
                "--cookbook-path #{cookbook_root} " \
                "--config #{new_resource.config} " \
                "--supermarket-site #{new_resource.site} " \
                "-u #{new_resource.user} " \
                "#{options}"
      shell_out!(command)
    end

    def cookbook_version_in_supermarket
      command = "knife supermarket show #{new_resource.cookbook} " \
                "#{new_resource.version} " \
                "--config #{new_resource.config} " \
                "--supermarket-site #{new_resource.site}"
      output = shell_out(command)

      # If we can show the cookbook::version, means it already exists
      output.exitstatus.zero? ? true : false
    end

    def supermarket_tmp_key_path
      ::File.join(delivery_workspace_cache, 'supermarket.pem')
    end

    def cookbook_root
      ::File.expand_path('..', new_resource.path)
    end
  end
end
