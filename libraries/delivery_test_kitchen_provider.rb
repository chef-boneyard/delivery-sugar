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
    class DeliveryTestKitchen < Chef::Provider
      attr_reader :test_kitchen

      def whyrun_supported?
        true
      end

      def load_current_resource
        # There is no existing resource to evaluate, but we are required
        # to override it.
      end

      def initialize(new_resource, run_context)
        super

        @test_kitchen = DeliverySugar::TestKitchen.new(
          new_resource.driver,
          new_resource.repo_path,
          run_context,
          yaml: new_resource.yaml,
          options: new_resource.options,
          suite: new_resource.suite,
          timeout: new_resource.timeout,
          environment: new_resource.environment
        )
      end

      def action_create
        kitchen('create')
      end

      def action_converge
        kitchen('converge')
      end

      def action_setup
        kitchen('setup')
      end

      def action_verify
        kitchen('verify')
      end

      def action_destroy
        kitchen('destroy')
      end

      def action_test
        # Destroy strategy to use after testing (passing, always, never)
        @test_kitchen.add_option('--destroy=always')
        kitchen('test')
      end

      private

      def kitchen(action)
        converge_by "[Test Kitchen] Run action :#{action} with yaml " \
                    "'#{@test_kitchen.yaml}' for #{@test_kitchen.suite} suite" do
          @test_kitchen.run(action)
          new_resource.updated_by_last_action(true)
        end
      end
    end
  end
end
