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

      action :create do
        kitchen('create')
      end

      action :converge do
        kitchen('converge')
      end

      action :setup do
        kitchen('setup')
      end

      action :verify do
        kitchen('verify')
      end

      action :destroy do
        kitchen('destroy')
      end

      action :test do
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
