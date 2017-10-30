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
    class DeliveryInspec < Chef::Resource
      include DeliverySugar::DSL
      provides :delivery_inspec

      def initialize(name, run_context = nil)
        super
        @resource_name = :delivery_inspec
        @provider = Chef::Provider::DeliveryInspec

        @inspec_test_path = '/test/recipes/'
        @repo_path = delivery_workspace_repo

        @action = :test
        @allowed_actions.push(:test)
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
      # The name of the OS of the infrastruture node
      #
      def os(arg = nil)
        set_or_return(
          :os,
          arg,
          kind_of: String
        )
      end

      #
      # The IP address of the infrastruture node
      #
      def infra_node(arg = nil)
        set_or_return(
          :infra_node,
          arg,
          kind_of: String, required: true
        )
      end

      #
      # The optional path to where the tests are located
      #
      def inspec_test_path(arg = nil)
        set_or_return(
          :inspec_test_path,
          arg,
          kind_of: String
        )
      end
    end
  end
end
