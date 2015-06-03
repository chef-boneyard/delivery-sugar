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

#
# rubocop:disable Style/ClassAndModuleCamelCase
#
module Chef_Delivery
  #
  # @deprecated Use DeliverySugar::ChefServer instead.
  #
  class ClientHelper
    def self.leave_client_mode_as_delivery
      print_deprecation_warning('leave')
      chef_server.send(:unload_server_config)
    end

    def self.enter_client_mode_as_delivery
      print_deprecation_warning('enter')
      chef_server.send(:load_server_config)
    end

    def self.chef_server
      @chef_server ||= DeliverySugar::ChefServer.new
    end

    def self.print_deprecation_warning(mode)
      ::Chef::Log.deprecation('Chef_Delivery::ClientHelper.' \
        "#{mode}_client_mode_as_delivery` is now deprecated. Please consider " \
        'using DeliverySugar::ChefServer#with_server_config instead.')
    end
  end
end
