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
require 'chef/mixin/shell_out'

class Chef
  class Provider
    class DeliveryGithub < Chef::Provider
      include Chef::Mixin::ShellOut

      def whyrun_supported?
        true
      end

      def load_current_resource
        @current_resource = Chef::Resource::DeliveryGithub.new(new_resource.name)

        git_remote_out = git_remote_shell_out('git remote --verbose').stdout.chomp
        match = git_remote_out.match(/^github\s+(\S+)/)
        @current_resource.remote_url match.nil? ? '' : match[1]
      end

      def action_push
        converge_by "Push #{new_resource.branch} branch to #{new_resource.remote_url}" do
          create_deploy_key
          create_ssh_wrapper_file
          create_git_remote
          tag_head
          push_to_github
          new_resource.updated_by_last_action(true)
        end
      end

      private

      #
      # Using a Chef `file` resource, put the deploy_key on disk.
      #
      # This key should allow the user to deploy to the specified github remote.
      # For information about setting up a github deploy key, please visit
      # https://developer.github.com/guides/managing-deploy-keys/#deploy-keys
      #
      # rubocop:disable AbcSize
      #
      def create_deploy_key
        file = Chef::Resource::File.new('deploy_key', run_context).tap do |f|
          f.path ::File.join(new_resource.cache_path,
                             "#{new_resource.remote_name}.pem")
          f.content new_resource.deploy_key
          f.mode '0600'
          f.sensitive true
        end
        file.run_action(:create)
      end

      #
      # Using a Chef `file` resource, create a ssh_wrapper template.
      #
      # This file is used to allow the `git` command to reference the deploy_key
      # we placed on disk in `create_deploy_key`.
      #
      def create_ssh_wrapper_file
        file = Chef::Resource::File.new('ssh_wrapper_file', run_context).tap do |f|
          f.path ::File.join(new_resource.cache_path, 'git_ssh')
          f.content ssh_wrapper_command
          f.mode '0755'
        end
        file.run_action(:create)
      end

      #
      # Create or update the URL for the github remote
      #
      def create_git_remote
        if @current_resource.remote_url == ''
          git_remote_shell_out("git remote add #{new_resource.remote_name} " \
                               "#{new_resource.remote_url}")
        elsif @current_resource.remote_url != new_resource.remote_url
          git_remote_shell_out("git remote set-url #{new_resource.remote_name} " \
                                "#{new_resource.remote_url}")
        end
      end

      #
      # Apply a tag to the current HEAD of the branch
      #
      def tag_head
        git_remote_shell_out("git tag #{res.tag} -am \"Tagging #{res.tag}\"") if res.tag
      end

      #
      # Push the specified branch to the github remote
      #
      def push_to_github
        git_remote_shell_out("git push #{res.remote_name} #{res.branch}")
        git_remote_shell_out("git push #{res.remote_name} --tags") if res.tag
      end

      # Method to shorten new_resource name
      def res
        new_resource
      end

      #
      # Return the contents of the SSH wrapper file. This file will allow
      # git to communicate with Github via SSH cleanly without needing a
      # ssh-agent or ~/.ssh/config
      #
      # @return [String]
      #
      def ssh_wrapper_command
        <<-EOH
unset SSH_AUTH_SOCK
ssh -o CheckHostIP=no \
    -o IdentitiesOnly=yes \
    -o LogLevel=INFO \
    -o StrictHostKeyChecking=no \
    -o PasswordAuthentication=no \
    -o UserKnownHostsFile=#{new_resource.cache_path}/delivery-git-known-hosts \
    -o IdentityFile=#{new_resource.cache_path}/#{new_resource.remote_name}.pem \
    $*
        EOH
      end

      #
      # Shell out to run a git command in the context of our repo
      #
      def git_remote_shell_out(command)
        shell_out!(
          command,
          cwd: new_resource.repo_path,
          env: {
            'GIT_SSH' => ::File.join(new_resource.cache_path, 'git_ssh')
          }
        )
      end
    end
  end
end
