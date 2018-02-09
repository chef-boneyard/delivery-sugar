resource_name :delivery_terraform

property :plan_dir, String, required: true
property :timeout, Integer, default: 1800, required: false

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
  %w(init plan apply show destroy).each { |x| tf(x) }
end

action_class do
  require 'json'
  include Chef::Mixin::ShellOut
  include DeliverySugar::DSL

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
  end

  def cmd(action) # rubocop:disable Metrics/MethodLength
    case action
    when 'apply'
      "terraform #{action} -input=false -auto-approve \
        -lock=false #{new_resource.plan_dir}"
    when 'init', 'plan'
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
    s = shell_out(cmd('state pull'), cwd: workflow_workspace_repo).stdout
    s == '' ? {} : JSON.parse(s)
  end

  def save_state
    node.run_state['terraform-state'] = state
    Chef::Log.info("Terraform state updated in node.run_state['terraform-state']")
  end

  def run(action) # rubocop:disable Metrics/MethodLength
    shell_out!(cmd(action),
               cwd: workflow_workspace_repo,
               live_stream: STDOUT,
               timeout: new_resource.timeout)
  rescue Mixlib::ShellOut::ShellCommandFailed, Mixlib::ShellOut::CommandTimeout
    shell_out(cmd('destroy'),
              cwd: workflow_workspace_repo,
              live_stream: STDOUT,
              timeout: new_resource.timeout)
    raise
  ensure
    save_state
  end
end
