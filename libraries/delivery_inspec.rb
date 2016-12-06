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

require 'chef/mixin/shell_out'
require_relative './delivery_dsl'
require 'chef/dsl'

module DeliverySugar
  #
  # This class is our interface to execute inspec tests
  #
  class Inspec
    include Chef::DSL::Recipe
    include DeliverySugar::DSL
    include Chef::Mixin::ShellOut
    attr_reader :repo_path, :os, :node
    attr_accessor :run_context, :infra_node

    #
    # Create a new Inspec object
    #
    # @param repo_path [String]
    #   The path to the project repository within the workspace
    # @param run_context [Chef::RunContext]
    #   The object that loads and tracks the context of the Chef run
    # @param os [String]
    #   The name of the OS of the infrastruture node
    # @param infra_node [string]
    #   The IP address of the infrastruture node
    #
    # @return [DeliverySugar::Inspec]
    #
    def initialize(repo_path, run_context, parameters = {})
      @repo_path = repo_path
      @run_context = run_context
      @os = parameters[:os]
      @infra_node = parameters[:infra_node]
      @inspec_test_path = parameters[:inspec_test_path]
    end

    #
    # Run inspec action
    #
    def run_inspec
      prepare_inspec
      shell_out!(
        "#{delivery_workspace_cache}/inspec.sh",
        cwd: @repo_path,
        live_stream: STDOUT
      )
    end

    def prepare_inspec
      case @os
      when 'linux'
        prepare_linux_inspec
      when 'windows'
        prepare_windows_inspec
      else
        fail "The operating system '#{@os}' is not supported"
      end
    end

    #
    # Create script for linux nodes
    #
    # rubocop:disable AbcSize
    # rubocop:disable Metrics/MethodLength
    def prepare_linux_inspec
      # Load secrets from delivery-secrets data bag
      secrets = get_project_secrets
      if secrets['inspec'].nil?
        fail 'Could not find secrets for inspec' \
             ' in delivery-secrets data bag.'
      end
      # Variables used for the linux inspec script
      cache = delivery_workspace_cache
      ssh_user = secrets['inspec']['ssh-user']
      ssh_private_key_file = "#{cache}/.ssh/#{secrets['inspec']['ssh-user']}.pem"
      ssh_hostname = @infra_node

      # Create directory for SSH key
      directory = Chef::Resource::Directory.new("#{cache}/.ssh", run_context)
      directory.recursive true
      directory.run_action(:create)

      # Create private key
      file = Chef::Resource::File.new(ssh_private_key_file, run_context).tap do |f|
        f.content secrets['inspec']['ssh-private-key']
        f.sensitive true
        f.mode '0400'
      end
      file.run_action(:create)

      # Create inspec script
      file = Chef::Resource::File.new("#{cache}/inspec.sh", run_context).tap do |f|
        f.content <<-EOF
chef exec inspec exec #{node['delivery']['workspace']['repo']}#{@inspec_test_path} -t ssh://#{ssh_user}@#{ssh_hostname} -i #{ssh_private_key_file}
        EOF
        f.sensitive true
        f.mode '0750'
      end
      file.run_action(:create)
    end

    #
    # Create script for Windows nodes
    #
    def prepare_windows_inspec
      # Load secrets from delivery-secrets data bag
      secrets = get_project_secrets
      if secrets['inspec'].nil?
        fail 'Could not find secrets for inspec' \
             ' in delivery-secrets data bag.'
      end
      # Variables used for the Windows inspec script
      cache = delivery_workspace_cache
      winrm_user = secrets['inspec']['winrm-user']
      winrm_password = secrets['inspec']['winrm-password']
      winrm_hostname = @infra_node

      # Create inspec script
      file = Chef::Resource::File.new("#{cache}/inspec.sh", run_context).tap do |f|
        f.content <<-EOF
chef exec inspec exec #{node['delivery']['workspace']['repo']}#{@inspec_test_path} -t winrm://#{winrm_user}@#{winrm_hostname} --password '#{winrm_password}'
        EOF
        f.sensitive true
        f.mode '0750'
      end
      file.run_action(:create)
    end

    # Returns the Chef::Node Object coming from the run_context
    def node
      run_context && run_context.node
    end
  end
end
