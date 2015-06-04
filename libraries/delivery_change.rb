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
  #
  # This class will represent a Delivery change object and provide information
  # and helpers for use inside Delivery phase run recipes.
  #
  class Change
    attr_reader :enterprise, :organization, :project, :pipeline,
                :stage, :patchset_branch, :scm_client, :workspace_repo,
                :merge_sha

    #
    # Create a new DeliverySugar::Change object
    #
    # @param [Chef::Node] node
    #   The Chef::Node object from the current runtime
    #
    # @return [DeliverySugar::Change]
    #
    # rubocop:disable AbcSize
    #
    def initialize(node)
      change = node['delivery']['change']
      workspace = node['delivery']['workspace']
      @enterprise = change['enterprise']
      @organization = change['organization']
      @project = change['project']
      @pipeline = change['pipeline']
      @stage = change['stage']
      @patchset_branch = change['patchset_branch']
      @merge_sha = change['sha']
      @workspace_repo = workspace['repo']
    end

    #
    # Return the acceptance environment name for the given change
    #
    # @return [String]
    #
    def acceptance_environment
      "acceptance-#{project_slug}-#{@pipeline}"
    end

    #
    # Return a list of Cookbook objects representing the cookbooks that have
    # been modified in the current changeset.
    #
    # @return [Array<DeliverySugar::Cookbook>]
    #
    def changed_cookbooks
      cookbooks = Set.new

      # Iterate throught the changed files to see if any belong to a cookbook
      changed_files.each do |changed_file|
        cookbooks << cookbook_from_member_file(changed_file)
      end

      # Check to see if the default workspace is a cookbook
      cookbooks << load_cookbook('/') if changed_files.length > 0

      # remove nil
      cookbooks.to_a.compact
    end

    #
    # Return a list of files that have changed in the current changset
    #
    # @return [Array<String>]
    #
    def changed_files
      second_branch = @merge_sha.nil? ? @patchset_branch : "#{@merge_sha}~1"
      scm_client.changed_files(@workspace_repo, @pipeline, second_branch)
    end

    #
    # Return the environment name for the current stage
    #
    # @return [String]
    #
    def environment_for_current_stage
      @stage == 'acceptance' ? acceptance_environment : @stage
    end

    #
    # Return a unique string to identify a Delivery project.
    #
    # @return [String]
    #
    def project_slug
      "#{@enterprise}-#{@organization}-#{@project}"
    end

    private

    #
    # Determine if the provided filename is part of a cookbook in the
    # cookbooks directory.
    #
    # @param changed_filed [String]
    #   The relative path to a file in the project
    #
    # @return [DeliverySugar::Cookbook, nil]
    #
    def cookbook_from_member_file(changed_file)
      result = changed_file.match(%r{^cookbooks/(.+)/})
      load_cookbook(result[0]) unless result.nil?
    end

    #
    # Try and create a Cookbook object based on a path. If that path is not a
    # cookbook, return nil.
    #
    # @param relative_path [String]
    #   The relative path to the cookbook in the project
    #
    # @return [DeliverySugar::Cookbook, NilClass]
    #
    def load_cookbook(relative_path)
      DeliverySugar::Cookbook.new(File.join(@workspace_repo, relative_path))
    rescue DeliverySugar::Exceptions::NotACookbook
      nil
    end

    #
    # Create a new SCM client to use to inspect the current changeset on disk
    #
    # @return [DeliverySugar::SCM]
    #
    def scm_client
      @scm_client ||= DeliverySugar::SCM.new
    end
  end
end
