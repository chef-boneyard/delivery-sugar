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
      # @param [String] branch1
      #   The name of a branch
      # @param [String] branch2
      #   The name of a branch
      #
      # @return [Array<String>]
      #
      def changed_files(workspace, branch1, branch2)
        puts "\n\ngit merge-base #{branch1} #{branch2}\n\n"
        sha1 = shell_out!("git merge-base #{branch1} #{branch2}", cwd: workspace)
               .stdout.chomp
        puts "\n\nSha1 = #{sha1}\n\n"
        shell_out!("git diff --name-only #{sha1} #{branch2}", cwd: workspace)
          .stdout.chomp.split("\n")
      end
    end
  end
end
