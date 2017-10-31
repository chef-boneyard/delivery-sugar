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
      # @return [String]
      #
      def merge_base(workspace, ref1, ref2)
        shell_out!("git merge-base #{ref1} #{ref2}", cwd: workspace).stdout.chomp
      end

      #
      # Get the contents of an object at a given revision.
      #
      # @param [String] workspace
      #   The fully-qualified path to the git repo on disk.
      # @param [String] path
      #   Path to an file relative to the repo root.
      # @param [String] ref
      #   A git reference or commit-ish string.
      #   If this is nil, reads from the current HEAD.
      #
      # @return [String] contents or nil if no such file is available.
      #
      def read_at_revision(workspace, path, ref = nil)
        ref ||= 'HEAD'
        cmd = shell_out("git show #{ref}:#{path}", cwd: workspace)
        cmd.stdout unless cmd.error?
      end

      #
      # Get the commit log for all commits between two refs inclusive. Resulting
      # array has commits in reverse chronological order.
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
      def commit_log(workspace, ref1, ref2)
        log = shell_out!("git log #{ref1}..#{ref2}", cwd: workspace).stdout
        log = log.split(/^commit /)
        log.shift
        log.map { |l| "commit #{l}".chomp }
      end
    end
  end
end
