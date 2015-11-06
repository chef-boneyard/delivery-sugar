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

# Including this is a temporary workaround to address a bug in chef-12.4.0.rc0
require 'chef/mixin/shell_out'

require 'chef/resource'

class Chef
  class Resource
    class DeliveryGithub < Chef::Resource
      provides :delivery_github

      def initialize(name, run_context = nil)
        super

        @resource_name = :delivery_github
        @provider = Chef::Provider::DeliveryGithub

        @branch = 'master'
        @repo = name
        @remote_name = 'github'
        @tag = nil

        @action = :push
        @allowed_actions.push(:push)
      end

      #
      # The branch to push to github
      #
      def branch(arg = nil)
        set_or_return(
          :branch,
          arg,
          kind_of: String
        )
      end

      #
      # The fully-qualified path to a directory where we can store files that
      # are required/created for this resource and provider.
      #
      # When used with the delivery-cli this will be the 'cache' directory
      # in the project workspace. That value is commonly available as
      # `node['delivery']['workspace']['cache']`
      #
      def cache_path(arg = nil)
        set_or_return(
          :cache_path,
          arg,
          kind_of: String, required: true
        )
      end

      #
      # The contents of the SSH deploy key configured in Github.
      #
      def deploy_key(arg = nil)
        set_or_return(
          :deploy_key,
          arg,
          kind_of: String, required: true
        )
      end

      #
      # The name we are giving to the Github remote
      #
      def remote_name(arg = nil)
        set_or_return(
          :remote_name,
          arg,
          kind_of: String
        )
      end

      #
      # The Github remote URL.
      #
      def remote_url(arg = nil)
        set_or_return(
          :remote_url,
          arg,
          kind_of: String, required: true
        )
      end

      #
      # The name of the Github repository. This includes the organization and
      # repository.
      #
      def repo(arg = nil)
        set_or_return(
          :repo,
          arg,
          kind_of: String
        )
      end

      #
      # The fully-qualified path to the directory where the code is on disk.
      #
      # When used with the delivery-cli this will be the 'repo' directory
      # in the project workspace. That value is commonly available as
      # `node['delivery']['workspace']['repo']`
      #
      def repo_path(arg = nil)
        set_or_return(
          :repo_path,
          arg,
          kind_of: String, required: true
        )
      end

      #
      # A tag to apply to HEAD and push along with your code.
      #
      def tag(arg = nil)
        set_or_return(
          :tag,
          arg,
          kind_of: String
        )
      end
    end
  end
end
