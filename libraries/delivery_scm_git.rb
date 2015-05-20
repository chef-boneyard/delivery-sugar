require 'chef/mixin/shell_out'

module DeliverySugar
  class SCM
    module Git
      include Chef::Mixin::ShellOut

      def changed_files(workspace, branch1, branch2)
        shell_out("git diff --name-only #{branch1} #{branch2}", cwd: workspace)
      end
    end
  end
end
