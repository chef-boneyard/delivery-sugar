resource_name :delivery_terraform

extend DeliverySugar::DSL

property :plan_dir, String, default: "#{delivery_workspace_repo}/files/default/terraform"
property :repo_path, String, default: delivery_workspace_repo

default_action :test

action :init do
  tf('init')
end

action :plan do
  tf('plan')
end

action :apply do
  tf('apply')
end

action :show do
  tf('show')
end

action :destroy do
  tf('destroy')
end

action :test do
  %w(init plan apply show destroy).each { |x| tf(x.to_s) }
end

action_class do
  require 'json'
  include Chef::Mixin::ShellOut

  def tf(action)
    preflight
    converge_by "[Terraform] Run action :#{action} " \
      "with *.tf files in #{new_resource.plan_dir}\n" do
      run(action)
      new_resource.updated_by_last_action(true)
    end
  end

  def preflight
    msg = 'Terraform preflight check: No such path for'
    fail "#{msg} plan_dir: #{new_resource.plan_dir}" unless ::File.exist?(
      new_resource.plan_dir
    )
    fail "#{msg} repo_path: #{new_resource.repo_path}" unless ::File.exist?(
      new_resource.repo_path
    )
  end

  def cmd(action)
    case action
    when 'init', 'plan', 'apply'
      "terraform #{action} -lock=false #{new_resource.plan_dir}"
    when 'destroy'
      "terraform #{action} -lock=false --force #{new_resource.plan_dir}"
    when 'show'
      "terraform #{action}"
    when 'state pull'
      "terraform #{action} 2>/dev/null"
    end
  end

  def state
    s = shell_out(cmd('state pull'), cwd: new_resource.repo_path).stdout
    s == '' ? {} : JSON.parse(s)
  end

  def save_state
    node.run_state['terraform-state'] = state
    Chef::Log.info("Terraform state updated in node.run_state['terraform-state']")
  end

  def run(action)
    shell_out!(cmd(action), cwd: new_resource.repo_path, live_stream: STDOUT)
  rescue Mixlib::ShellOut::ShellCommandFailed, Mixlib::ShellOut::CommandTimeout
    shell_out(cmd('destroy'), cwd: new_resource.repo_path, live_stream: STDOUT)
    raise
  ensure
    save_state
  end
end
