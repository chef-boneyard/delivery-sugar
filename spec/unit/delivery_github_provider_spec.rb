require 'spec_helper'
require 'chef/node'
require 'chef/event_dispatch/dispatcher'
require 'chef/run_context'

describe Chef::Provider::DeliveryGithub do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:new_resource) { Chef::Resource::DeliveryGithub.new('org/repo') }
  let(:current_resource) { Chef::Resource::DeliveryGithub.new('org/repo') }
  let(:provider) { described_class.new(new_resource, run_context) }

  let(:github_remote_a) { 'git@github.com:org/repo.git' }
  let(:github_remote_b) { 'git@github.com:org2/repo2.git' }

  let(:shellout_options) do
    {
      cwd: 'workspace/repo',
      env: {
        'GIT_SSH' => 'workspace/cache/git_ssh'
      }
    }
  end

  before do
    provider.current_resource = current_resource
    new_resource.deploy_key 'secret'
    new_resource.remote_name 'unit'
    new_resource.remote_url github_remote_a
    new_resource.repo_path 'workspace/repo'
    new_resource.cache_path 'workspace/cache'
  end

  describe '#load_current_resource' do
    let(:shellout_git) { double('git remote command', stdout: remote_output) }
    let(:origin_url) { 'ssh://user@chef@delivery.server.lan:8989/ent/org/proj/repo' }

    before do
      expect(provider).to receive(:shell_out!)
        .with('git remote --verbose', shellout_options).and_return(shellout_git)
    end

    context 'when the remote is not present' do
      let(:remote_output) do
        <<-EOF
origin  #{origin_url} (fetch)
origin  #{origin_url} (push)
        EOF
      end

      it 'sets current_resource.remote_url to an empty string' do
        provider.load_current_resource
        expect(provider.current_resource.remote_url).to eql('')
      end
    end

    context 'when the remote is present' do
      let(:remote_output) do
        <<-EOF
origin  #{origin_url} (fetch)
origin  #{origin_url} (push)
github  #{github_remote_b} (fetch)
github  #{github_remote_b} (push)
        EOF
      end

      it 'sets current_resource.remote_url to value' do
        provider.load_current_resource
        expect(provider.current_resource.remote_url).to eql(github_remote_b)
      end
    end
  end

  describe '#action_push' do
    it 'pushes the given branch to github' do
      expect(provider).to receive(:create_deploy_key)
      expect(provider).to receive(:create_ssh_wrapper_file)
      expect(provider).to receive(:create_git_remote)
      expect(provider).to receive(:tag_head)
      expect(provider).to receive(:push_to_github)
      provider.action_push
    end
  end

  describe '#create_deploy_key' do
    let(:file_resource) { double('File#deploy_key') }

    it 'uses a Chef File resource to create the deploy key file' do
      expect(Chef::Resource::File).to receive(:new).with('deploy_key', run_context)
        .and_return(file_resource)
      expect(file_resource).to receive(:path).with('workspace/cache/unit.pem')
      expect(file_resource).to receive(:content).with('secret')
      expect(file_resource).to receive(:mode).with('0600')
      expect(file_resource).to receive(:sensitive).with(true)
      expect(file_resource).to receive(:run_action).with(:create)
      provider.send(:create_deploy_key)
    end
  end

  describe '#create_ssh_wrapper_file' do
    let(:file_resource) { double('File#ssh_wrapper_file') }
    let(:git_ssh) do
      <<-EOH
unset SSH_AUTH_SOCK
ssh -o CheckHostIP=no \
    -o IdentitiesOnly=yes \
    -o LogLevel=INFO \
    -o StrictHostKeyChecking=no \
    -o PasswordAuthentication=no \
    -o UserKnownHostsFile=workspace/cache/delivery-git-known-hosts \
    -o IdentityFile=workspace/cache/unit.pem \
    $*
      EOH
    end

    it 'uses a Chef File resource to create the SSH wrapper file' do
      expect(Chef::Resource::File).to receive(:new).with('ssh_wrapper_file', run_context)
        .and_return(file_resource)
      expect(file_resource).to receive(:path).with('workspace/cache/git_ssh')
      expect(file_resource).to receive(:content).with(git_ssh)
      expect(file_resource).to receive(:mode).with('0755')
      expect(file_resource).to receive(:run_action).with(:create)
      provider.send(:create_ssh_wrapper_file)
    end
  end

  describe '#create_git_remote' do
    context 'when current & existing values do not match' do
      before { provider.current_resource.remote_url github_remote_b }

      it 'updates the remote' do
        expect(provider).to receive(:shell_out!)
          .with("git remote set-url unit #{github_remote_a}", shellout_options)
        provider.send(:create_git_remote)
      end
    end

    context 'when current & existing values match' do
      before { provider.current_resource.remote_url github_remote_a }

      it 'does nothing' do
        expect(provider).to_not receive(:shell_out!)
          .with("git remote set-url unit #{github_remote_a}", shellout_options)
        provider.send(:create_git_remote)
      end
    end
  end

  describe '#tag_head' do
    describe 'when a tag has been provided' do
      before do
        new_resource.tag '0.1.0'
      end

      it 'applies the tag to head' do
        expect(provider).to receive(:shell_out!)
          .with('git tag 0.1.0 -am "Tagging 0.1.0"', shellout_options)
        provider.send(:tag_head)
      end
    end

    describe 'when no tag has been provided' do
      it 'does nothing' do
        expect(provider).to_not receive(:shell_out!)
          .with(/git tag/)
        provider.send(:tag_head)
      end
    end
  end

  describe '#push_to_github' do
    describe 'when a tag has been provided' do
      before do
        new_resource.tag '0.1.0'
      end

      it 'pushes branch and tags to github remote' do
        expect(provider).to receive(:shell_out!)
          .with('git push unit master', shellout_options)
        expect(provider).to receive(:shell_out!)
          .with('git push unit --tags', shellout_options)
        provider.send(:push_to_github)
      end
    end

    describe 'when no tag has been provided' do
      it 'only pushes branch to github remote' do
        expect(provider).to receive(:shell_out!)
          .with('git push unit master', shellout_options)
        expect(provider).not_to receive(:shell_out!)
          .with('git push unit --tags', shellout_options)
        provider.send(:push_to_github)
      end
    end
  end
end
