require 'chef/mixin/shell_out'

module DeliverySugar
  class SCM
    module Git
      include Chef::Mixin::ShellOut

      def changed_files(workspace, branch1, branch2)
        sha1 = shell_out("git merge-base #{branch1} #{branch2}", cwd: workspace)
               .stdout.chomp
        shell_out("git diff --name-only #{sha1} #{branch2}", cwd: workspace)
          .stdout.chomp.split("\n")
      end
    end
  end
end
