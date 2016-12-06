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

class Chef
  class Provider
    class DeliveryInspec < Chef::Provider
      attr_reader :inspec

      def whyrun_supported?
        true
      end

      def load_current_resource
        # There is no existing resource to evaluate, but we are required
        # to override it.
      end

      def initialize(new_resource, run_context)
        super

        @inspec = DeliverySugar::Inspec.new(
          new_resource.repo_path,
          run_context,
          os: new_resource.os,
          infra_node: new_resource.infra_node,
          inspec_test_path: new_resource.inspec_test_path
        )
      end

      def action_test
        converge_by 'Run inspec tests' do
          @inspec.run_inspec
          new_resource.updated_by_last_action(true)
        end
      end
    end
  end
end
