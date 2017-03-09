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
    class DeliveryPushJob < Chef::Resource
      include DeliverySugar::DSL
      provides :delivery_push_job

      def initialize(name, run_context = nil)
        super
        @resource_name = :delivery_push_job

        @command = name
        @timeout = 30 * 60 # 30 minutes
        @nodes = []
        @quorum = nil
        @chef_config_file = delivery_knife_rb

        @provider = Chef::Provider::DeliveryPushJob
        @action = :dispatch
        @allowed_actions.push(:dispatch)
      end

      #
      # The fully-qualified path to the chef config associated with the Chef
      # Server that is hosting the Push Jobs server.
      #
      def chef_config_file(arg = nil)
        set_or_return(
          :chef_config_file,
          arg,
          kind_of: String
        )
      end

      #
      # The white-listed command you wish the Push Job server to execute.
      #
      def command(arg = nil)
        set_or_return(
          :command,
          arg,
          kind_of: String
        )
      end

      #
      # The list of nodes you wish to execute the push job on.
      #
      def nodes(arg = nil)
        @quorum ||= arg.length unless arg.nil?
        set_or_return(
          :nodes,
          arg,
          kind_of: Array
        )
      end

      #
      # The timeout for the push job
      #
      def timeout(arg = nil)
        set_or_return(
          :timeout,
          arg,
          kind_of: Integer
        )
      end

      #
      # The number of nodes to reach quorum for the job
      #
      def quorum(arg = nil)
        set_or_return(
          :quorum,
          arg,
          kind_of: Integer
        )
      end
    end
  end
end
