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
  # rubocop:disable ClassLength
  #
  class Change
    attr_reader :enterprise, :organization, :project, :pipeline,
                :stage, :phase, :patchset_branch, :scm_client, :workspace_path,
                :workspace_repo, :workspace_cache, :workspace_chef, :workspace_root,
                :change_id, :merge_sha, :build_user

    #
    # Create a new DeliverySugar::Change object
    #
    # @param [Chef::Node] node
    #   The Chef::Node object from the current runtime
    #
    # @return [DeliverySugar::Change]
    #
    # rubocop:disable AbcSize
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable AccessorMethodName
    # rubocop:disable CyclomaticComplexity
    # rubocop:disable PerceivedComplexity
    #
    def initialize(node)
      change = node['delivery']['change']
      workspace = node['delivery']['workspace']
      @build_user = node['delivery_builder']['build_user']
      @workspace_repo = workspace['repo']
      @workspace_cache = workspace['cache']
      @workspace_chef = workspace['chef']
      @workspace_root = workspace['root']
      @workspace_path = node['delivery']['workspace_path'] ||
                        '/var/opt/delivery/workspace'
      @enterprise = change['enterprise']
      @organization = change['organization']
      @stage = change['stage']
      @phase = change['phase']
      @project = change['project']
      @pipeline = change['pipeline']
      @change_id = change['change_id']
      @merge_sha = change['sha']
      @patchset_branch = change['patchset_branch']
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
      cookbooks << load_cookbook('/') unless changed_files.empty?

      # remove nil
      cookbooks.to_a.compact
    end

    #
    # Return a list of files that have changed in the current changset
    #
    # @return [Array<String>]
    #
    def changed_files
      if @merge_sha.empty?
        merge_base = scm_client.merge_base(@workspace_repo, "origin/#{@pipeline}",
                                           "origin/#{@patchset_branch}")
        scm_client.changed_files(@workspace_repo, merge_base,
                                 "origin/#{@patchset_branch}")
      else
        scm_client.changed_files(@workspace_repo, "#{@merge_sha}~1", @merge_sha)
      end
    end

    #
    # Return a list of directories that have changed in the current changeset
    #
    # @param depth [Integer] The directorty depth to keep
    # @return [Array<String>]
    #
    def changed_dirs(depth = nil)
      true_depth = depth.nil? ? 9999 : depth + 1
      modified_dirs = Set.new

      changed_files.each do |changed_file|
        changed_dir_tree = Pathname(changed_file).dirname.descend.to_a
        modified_dirs.merge(changed_dir_tree.take(true_depth).map(&:to_s))
      end

      # If there were _any_ changed files, add that root was also changed
      modified_dirs << '.' unless modified_dirs.empty?

      modified_dirs.to_a
    end

    #
    # Return an array of commits from the SCM log.
    #
    # @return [Array<String>]
    def change_log
      if @merge_sha.empty?
        merge_base = scm_client.merge_base(@workspace_repo, "origin/#{@pipeline}",
                                           "origin/#{@patchset_branch}")
        scm_client.commit_log(@workspace_repo, merge_base,
                              "origin/#{@patchset_branch}")
      else
        scm_client.commit_log(@workspace_repo, "#{@merge_sha}^", @merge_sha)
      end
    end

    #
    # Gets the metadata for a given cookbook at a specified revision.
    #
    # @param [String] the path to the cookbook.
    # @param [String] a revision string that can identify the version
    #   of the source repo to look in. For git, this is a "commit-ish"
    #   refspec.
    #
    # @return Cookbook that corresponds to the parsed metadata  or nil
    #   if the cookbook doesn't exist at that path at the revision
    #   requested.
    #
    def cookbook_metadata(path, revision = nil)
      if revision
        read_file = lambda do |fpath|
          fpath_p = Pathname.new(fpath)
          workspace_repo_p = Pathname.new(@workspace_repo)
          relative_path = fpath_p.relative_path_from(workspace_repo_p).to_s
          scm_client.read_at_revision(@workspace_repo, relative_path, revision)
        end
      end
      # Don't pass in any read_file callback if we don't need to access
      # a specific revision.  Just let Cookbook read from the file system.
      Cookbook.new(path, read_file)
    rescue Exceptions::NotACookbook
      nil
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
    # Return a unique string to identify an Automate enterprise
    #
    # @return [String]
    #
    def enterprise_slug
      @enterprise
    end

    #
    # Return a unique string to identify an Automate project.
    #
    # @return [String]
    #
    def project_slug
      "#{@enterprise}-#{@organization}-#{@project}"
    end

    #
    # Return a unique string to identify an Automate organization.
    #
    # @return [String]
    #
    def organization_slug
      "#{@enterprise}-#{@organization}"
    end

    #
    # Return an array of cookbooks for the current change.
    #
    # @return [Array<DeliverySugar::Cookbook>]
    #
    def get_all_project_cookbooks
      cookbooks = []
      cookbooks << load_cookbook('/')

      cookbook_dir_path = workspace_repo + '/cookbooks'
      if File.directory?(cookbook_dir_path)
        cookbook_dir = Dir.new(cookbook_dir_path)
        cookbook_dir.each do |dir|
          cookbooks << load_cookbook("/cookbooks/#{dir}") unless dir == '.' || dir == '..'
        end
      end

      cookbooks.compact
    end

    #
    # Define a project application, upload it as a data bag item,
    # and set its version pin for the acceptance env.
    #
    # @param [String] app_name
    #   A string representing your application's name
    # @param [String] app_version
    #   A string representing your application's version
    # @param [Hash] app_attributes
    #   A hash of attributes that make up your application at app_version.
    #   Should contain key, strings, and arrays.
    #
    # @return [Chef::Environment]
    #
    def define_project_application(app_name, app_version, app_attributes)
      Chef::Log.warn wrong_stage_for_define_project_application_error if @stage != 'build'
      update_data_bag_with_application_attributes(app_name, app_version, app_attributes)
      set_application_pin_on_acceptance_environment(app_name, app_version)
    end

    #
    # Load a project application's attributes previously defined by
    # define_project_application(). Will be loaded at the current
    # version pin for environment (must be in acceptance, union,
    # rehearsal, or delivered stage).
    #
    # @param [String] app_name
    #   A string representing your application's name
    #
    # @return [Chef::Environment]
    #
    def get_project_application(app_name)
      if @stage == 'build' || @stage == 'verify'
        Chef::Log.warn wrong_stage_for_get_project_application_error
      end

      env = begin
              load_chef_environment(environment_for_current_stage)
            rescue Net::HTTPServerException => http_e
              raise http_e unless http_e.response.code == '404'
              raise "Could not load the environment for #{@stage} "\
                    'from helper get_project_application.\n' \
                    'Make sure you are running include_recipe '\
                    '"delivery-truck::provision" before you call this helper.'
            end

      raise app_not_found_error(app_name) if env.override_attributes['applications'].nil?

      app_version = env.override_attributes['applications'][app_name]

      raise app_not_found_error(app_name) if app_version.nil?

      # Load the data bag for this version of the application into a hash.
      begin
        load_data_bag_item(@project, app_slug(app_name, app_version)).raw_data
      rescue Net::HTTPServerException => http_e
        raise http_e unless http_e.response.code == '404'
        raise app_not_found_error(app_name)
      end
    end

    #
    # Return an array of cookbooks for the current change.
    # Not in Delivery DSL. Used by define_project_application().
    #
    # @param [String] app_name
    #   A string representing your application's name
    # @param [String] app_version
    #   A string representing your application's version
    # @param [Hash] app_attributes
    #   A hash of attributes that make up your application at app_version.
    #   Should contain key, strings, and arrays.
    #
    # @return [Chef::DataBagItem]
    #
    def update_data_bag_with_application_attributes(app_name, app_version, app_attributes)
      data_bag = new_data_bag
      data_bag.name(@project)

      chef_server.with_server_config do
        # Due to strange Chef::DataBag code, this will either create an empty
        # project data bag, or do nothing.
        data_bag.save
      end

      data_bag_item_data = {
        'id' => app_slug(app_name, app_version),
        'version' => app_version,
        'name' => app_name
      }
      data_bag_item_data.merge!(app_attributes)
      data_bag_item = new_data_bag_item
      data_bag_item.data_bag(@project)
      set_data_bag_item_content(data_bag_item, data_bag_item_data)

      chef_server.with_server_config do
        data_bag_item.save
      end
      data_bag_item
    end

    #
    # Return an array of cookbooks for the current change.
    # Not in Delivery DSL. Used by define_project_application().
    #
    # @param [String] app_name
    #   A string representing your application's name
    # @param [String] app_version
    #   A string representing your application's version
    # @param [Hash] app_attributes
    #   A hash of attributes that make up your application at app_version.
    #   Should contain key, strings, and arrays.
    #
    # @return [Chef::Environment]
    #
    def set_application_pin_on_acceptance_environment(app_name, app_version)
      env = begin
              load_chef_environment(acceptance_environment)
            rescue Net::HTTPServerException => http_e
              raise http_e unless http_e.response.code == '404'
              env = new_environment
              env.name(acceptance_environment)
              create_chef_environment(env)
              env
            end

      env.override_attributes['applications'] ||= {}
      env.override_attributes['applications'][app_name] = app_version

      save_chef_environment(env)
      env
    end

    #
    # Generates a unique slug given an app_name and version. Any invalid
    # characters are replaced by an underscore.
    #
    # @param [String] app_name
    #   A string representing your application's name
    # @param [String] app_version
    #   A string representing your application's version
    #
    # @return [String]
    def app_slug(app_name, app_version)
      # Regex is a negated version of `Chef::DataBagItem::VALID_ID`.
      # See https://git.io/vSqLs for more details
      "#{project_slug}-#{app_name}-#{app_version}".gsub(/[^\.\-[:alnum:]_]/, '_')
    end

    # Not in Delivery DSL. Used by define_project_application().
    def wrong_stage_for_define_project_application_error
      'The helper define_project_application should be called at the ' \
      'end of the build phase (usually in the publish stage).\n' \
      "You called it from the #{@stage} stage."
    end

    # Not in Delivery DSL. Used by get_project_application().
    def wrong_stage_for_get_project_application_error
      'The helper get_project_application must be called from the ' \
      'acceptance, union, rehearsal, or delivered stage.\n' \
      "You called it from the #{@stage} stage."
    end

    # Not in Delivery DSL. Used by get_project_application().
    def app_not_found_error(app_name)
      "Could not find app #{app_name} for stage #{@stage}. " \
      'Have you defined it with define_project_application\n' \
      'If so, it means delivery-truck::provision has not run.\n' \
      'Either call get_project_application() from a ruby_block, ' \
      'a seperate include_recipe or in the deploy recipe instead of provision'
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
      result = changed_file.match(%r{^cookbooks/([a-zA-Z0-9_-]*)})
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

    ####################################################
    # Helper methods abstracted to make testing easier #
    ####################################################

    def new_environment
      Chef::Environment.new
    end

    def new_data_bag
      Chef::DataBag.new
    end

    def new_data_bag_item
      Chef::DataBagItem.new
    end

    def load_data_bag_item(data_bag_name, data_bag_item_name)
      chef_server.with_server_config do
        Chef::DataBagItem.load(data_bag_name, data_bag_item_name)
      end
    end

    def set_data_bag_item_content(data_bag_item, content)
      data_bag_item.raw_data = content
    end

    def load_chef_environment(env_name)
      chef_server.with_server_config do
        Chef::Environment.load(env_name)
      end
    end

    def create_chef_environment(env)
      chef_server.with_server_config do
        env.create
      end
    end

    def save_chef_environment(env)
      chef_server.with_server_config do
        env.save
      end
    end

    def chef_server
      @chef_server ||= DeliverySugar::ChefServer.new
    end
  end
end
