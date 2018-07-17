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
    class DeliveryTestKitchen < Chef::Resource
      include DeliverySugar::DSL
      provides :delivery_test_kitchen

      # rubocop:disable MethodLength
      def initialize(name, run_context = nil)
        super
        @resource_name = :delivery_test_kitchen
        @provider = Chef::Provider::DeliveryTestKitchen

        @yaml      = '.kitchen.yml'
        @suite     = 'all'
        @options   = ''
        @timeout   = 3600
        @repo_path = delivery_workspace_repo
        @environment = {}

        @timeout   = 3600
        @action    = :test
        %w(create converge setup verify destroy test).each do |a|
          @allowed_actions.push(a.to_sym)
        end
      end

      #
      # The test kitchen driver
      #
      def driver(arg = nil)
        set_or_return(
          :driver,
          arg,
          kind_of: String,
          required: true
        )
      end

      #
      # The test kitchen shell environemnt variables
      #
      def environment(arg = nil)
        set_or_return(
          :environment,
          arg,
          kind_of: Hash
        )
      end

      #
      # The name of the .kitchen.yml
      #
      def yaml(arg = nil)
        set_or_return(
          :yaml,
          arg,
          kind_of: String
        )
      end

      #
      # The fully-qualified path to the directory where the code is on disk
      #
      def repo_path(arg = nil)
        set_or_return(
          :repo_path,
          arg,
          kind_of: String
        )
      end

      #
      # The suite name that this resource is going to run
      #
      def suite(arg = nil)
        set_or_return(
          :suite,
          arg,
          kind_of: String
        )
      end

      #
      # Additional options to pass to test-kitchen
      #
      def options(arg = nil)
        set_or_return(
          :options,
          arg,
          kind_of: String
        )
      end

      #
      # Adjustable timeout for Test Kitchen
      #
      def timeout(arg = nil)
        set_or_return(
          :timeout,
          arg,
          kind_of: Integer
        )
      end
    end
  end
end
