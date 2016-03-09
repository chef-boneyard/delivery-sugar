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

module DeliverySugar
  class SCM
    #
    # This is the Git implementation of our SCM library.
    #
    module Git
      include Chef::Mixin::ShellOut

      #
      # Inspect the git history to return the names of files that have changed
      # between the two given branches.
      #
      # @param [String] workspace
      #   The fully-qualified path to the git repo on disk
      # @param [String] ref1
      #   A git reference (branch, sha, etc)
      # @param [String] ref2
      #   A git reference (branch, sha, etc)
      #
      # @return [Array<String>]
      #
      def changed_files(workspace, ref1, ref2)
        shell_out!("git diff --name-only #{ref1} #{ref2}", cwd: workspace)
          .stdout.chomp.split("\n")
      end

      #
      # Get the merge_base sha for the two references specified.
      #
      # @param [String] workspace
      #   The fully-qualified path to the git repo on disk
      # @param [String] ref1
      #   A git reference (branch, sha, etc)
      # @param [String] ref2
      #   A git reference (branch, sha, etc)
      #
      # @return [Array<String>]
      #
      def merge_base(workspace, ref1, ref2)
        shell_out!("git merge-base #{ref1} #{ref2}", cwd: workspace).stdout.chomp
      end

      #
      # Takes a block and executes it while the repo is checked out to the given
      # ref. Restores the repo back to the original ref/HEAD state after the
      # block finishes executing.
      #
      # @param [String] workspace
      #   The fully-qualified path to the git repo on disk
      # @param [String] ref
      #   A valid refname
      #
      # @return what the block returns
      #
      def checkout(workspace, ref)
        # We assume that the repos are clean and that checking out a different
        # can be done with forcing/losing state.
        current_ref =
          shell_out!('git rev-parse --abbrev-ref HEAD', cwd: workspace).stdout.chomp
        if current_ref == 'HEAD'
          current_ref = shell_out!('git rev-parse HEAD', cwd: workspace).stdout.chomp
        end

        begin
          shell_out!("git checkout #{ref}", cwd: workspace)
          yield
        ensure
          shell_out!("git checkout #{current_ref}", cwd: workspace)
        end
      end
    end
  end
end
