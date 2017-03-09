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
    class DeliveryPushJob < Chef::Provider
      attr_reader :push_job

      def whyrun_supported?
        true
      end

      def load_current_resource
        # There is no existing resource to evaluate, but we are required
        # to override it.
      end

      def define_resource_requirements
        requirements.assert(:dispatch) do |a|
          a.assertion { ::File.exist?(new_resource.chef_config_file) }
          a.failure_message(
            RuntimeError,
            "The config file \"#{new_resource.chef_config_file}\" does not exist."
          )
        end
      end

      def initialize(new_resource, run_context)
        super

        @push_job = DeliverySugar::PushJob.new(
          new_resource.chef_config_file,
          new_resource.command,
          new_resource.nodes,
          new_resource.timeout,
          new_resource.quorum
        )
      end

      def action_dispatch
        if new_resource.nodes.empty?
          Chef::Log.info("Zero nodes passed to 'delivery_push_job'")
          return
        end

        converge_by("Dispatch push jobs for #{new_resource.command} on " \
                    "#{new_resource.nodes.join(',')}") do
          @push_job.dispatch
          @push_job.wait
          new_resource.updated_by_last_action(true)
        end
      end
    end
  end
end
