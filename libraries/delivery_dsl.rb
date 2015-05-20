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

module DeliverySugar
  module DSL
    def delivery_change
      @@delivery_change ||= DeliverySugar::Change.new(node)
    end

    def delivery_environment
      delivery_change.environment_for_current_stage
    end

    def get_acceptance_environment
      delivery_change.acceptance_environment
    end

    def changed_files
      delivery_change.changed_files
    end
  end
end
