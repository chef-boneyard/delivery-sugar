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

class Chef
  class Resource
    class DeliverySupermarket < Chef::Resource
      include DeliverySugar::DSL
      provides :delivery_supermarket

      # rubocop:disable MethodLength
      def initialize(name, run_context = nil)
        super
        @resource_name = :delivery_supermarket
        @provider = Chef::Provider::DeliverySupermarket
        cookbook = DeliverySugar::Cookbook.new(delivery_workspace_repo)

        @site           = 'https://supermarket.chef.io'
        @cookbook_name  = cookbook.name
        @cookbook_path  = cookbook.path
        @config         = delivery_knife_rb
        @user           = 'delivery'
        @action         = :share
        @allowed_actions.push(:share)
      end

      #
      # The Supermarket site
      #
      def site(arg = nil)
        set_or_return(
          :site,
          arg,
          kind_of: String
        )
      end

      #
      # The cokbook name 
      #
      def cookbook_name(arg = nil)
        set_or_return(
          :cookbook_name,
          arg,
          kind_of: String
        )
      end

      #
      # The fully-qualified path to the directory where the cookbook is on disk
      #
      def cookbook_path(arg = nil)
        set_or_return(
          :repo_path,
          arg,
          kind_of: String
        )
      end

      #
      # The knife.rb config file on disk
      #
      def config(arg = nil)
        set_or_return(
          :config,
          arg,
          kind_of: String
        )
      end

      #
      # The Supermarket user
      #
      def user(arg = nil)
        set_or_return(
          :user,
          arg,
          kind_of: String
        )
      end

      #
      # The Supermarket key
      #
      def key(arg = nil)
        set_or_return(
          :key,
          arg,
          kind_of: String
        )
      end
    end
  end
end
