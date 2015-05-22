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

require_relative 'delivery_scm_git'

module DeliverySugar
  #
  # This is the class that will be the interface to talk to whatever
  # SCM client is currently being used. At the moment that is only Git
  # so we are automatically including the Git implementation.
  #
  class SCM
    include DeliverySugar::SCM::Git
  end
end
