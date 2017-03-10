require 'spec_helper'

describe DeliverySugar::PushJob do
  def mock_job_rest_get
    subject.instance_variable_set(:@job_uri, job_uri)
    allow(chef_server).to receive(:rest).with(:get, job_uri).and_return(job)
  end
  let(:chef_config_file) { '/var/opt/delivery/workspace/.chef/knife.rb' }
  let(:command) { 'chef-client' }
  let(:nodes) { %w(node1 node2) }
  let(:nodes_body) { {} }
  let(:status) { 'voting' }
  let(:timeout) { 10 }
  let(:quorum) { 1 }
  let(:chef_server) { double('ChefServer Object') }

  let(:job_uri) { 'http://localhost/organizations/ORG_NAME/pushy/jobs/ID' }
  let(:job) do
    {
      'id' => 'aaaaaaaaaaaa25fd67fa8715fd547d3d',
      'command' => command,
      'run_timeout' => timeout,
      'status' => status,
      'created_at' => 'Tue, 04 Sep 2012 23:01:02 GMT',
      'updated_at' => 'Tue, 04 Sep 2012 23:07:56 GMT',
      'nodes' => nodes_body
    }
  end

  subject { described_class.new(chef_config_file, command, nodes, timeout, quorum) }

  before do
    allow(DeliverySugar::ChefServer).to receive(:new).with(chef_config_file)
      .and_return(chef_server)
  end

  describe '#initialize' do
    it 'sets the variables' do
      expect(subject.chef_server).to eql(chef_server)
      expect(subject.command).to eql(command)
      expect(subject.nodes).to eql(nodes)
      expect(subject.quorum).to eql(quorum)
    end

    context 'when nodes are NOT an array of strings' do
      let(:nodes) do
        [
          double('node1'),
          double('node2')
        ]
      end

      it 'raises an error' do
        expect { subject }.to raise_error
      end
    end

    context 'when nodes is an empty array' do
      let(:nodes) { [] }
      it 'should not raise error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when quorum is not initialized' do
      let(:quorum) { nil }
      it 'should equal number of nodes' do
        expect(subject.quorum).to eq(nodes.length)
      end
    end
  end

  describe '#dispatch' do
    let(:response) { { 'uri' => job_uri } }
    let(:body) do
      {
        'command' => command,
        'nodes' => nodes,
        'run_timeout' => timeout,
        'quorum' => quorum
      }
    end

    it 'submits job to Push Job Server' do
      expect(chef_server).to receive(:rest).with(:post, '/pushy/jobs', {}, body)
        .and_return(response)
      allow(chef_server).to receive(:rest).with(:get, job_uri).and_return(job)
      subject.dispatch
      expect(subject.job_uri).to eql(job_uri)
    end
  end

  describe '#refresh' do
    before do
      subject.instance_variable_set(:@job_uri, job_uri)
    end

    it 'sets/updates state attributes in the object' do
      expect(chef_server).to receive(:rest).with(:get, job_uri).and_return(job)
      subject.refresh
      expect(subject.id).to eql(job['id'])
      expect(subject.status).to eql(job['status'])
      expect(subject.created_at).to eql(DateTime.parse(job['created_at']))
      expect(subject.updated_at).to eql(DateTime.parse(job['updated_at']))
      expect(subject.results).to eql(job['nodes'])
    end
  end

  describe '#wait' do
    let(:push_job_failed_error) { DeliverySugar::Exceptions::PushJobFailed }
    before { mock_job_rest_get }

    context 'when timeout has passed' do
      before do
        allow(subject).to receive(:timed_out?).and_return(true)
      end

      it 'raises PushJobFailed exception' do
        expect { subject.wait }.to raise_error(push_job_failed_error)
      end
    end

    context 'when job has completed' do
      before do
        allow(subject).to receive(:timed_out?).and_return(false)
        allow(subject).to receive(:complete?).and_return(true)
      end

      context 'and job was successful' do
        before do
          allow(subject).to receive(:failed?).and_return(false)
          allow(subject).to receive(:successful?).and_return(true)
        end

        it 'returns without error' do
          expect { subject.wait }.not_to raise_error
        end
      end

      context 'and job was unsuccessful' do
        before do
          allow(subject).to receive(:failed?).and_return(true)
          allow(subject).to receive(:successful?).and_return(false)
        end

        it 'raises PushJobFailed exception' do
          expect { subject.wait }.to raise_error(push_job_failed_error)
        end
      end
    end
  end

  describe '#successful?' do
    before do
      mock_job_rest_get
      subject.refresh
    end

    context 'when status is not complete' do
      before { allow(subject).to receive(:complete?).and_return(false) }

      it 'returns false' do
        expect(subject.successful?).to eql(false)
      end
    end

    context 'when status is complete' do
      before { allow(subject).to receive(:complete?).and_return(true) }

      context 'and all nodes were successful' do
        let(:nodes_body) do
          {
            'succeeded' => nodes
          }
        end

        it 'returns true' do
          expect(subject.successful?).to eql(true)
        end
      end

      context 'and not all nodes were successful' do
        let(:nodes_body) do
          {
            'succeeded' => ['node1'],
            'failed' => ['node2']
          }
        end

        it 'returns false' do
          expect(subject.successful?).to eql(false)
        end
      end
    end
  end

  describe '#failed?' do
    before(:each) do
      mock_job_rest_get
      subject.refresh
    end

    context 'when status is not complete' do
      before { allow(subject).to receive(:complete?).and_return(false) }

      it 'returns false' do
        expect(subject.failed?).to eql(false)
      end
    end

    context 'when status is complete' do
      before { allow(subject).to receive(:complete?).and_return(true) }

      context 'and all nodes were successful' do
        let(:nodes_body) do
          {
            'succeeded' => nodes
          }
        end

        it 'returns false' do
          expect(subject.failed?).to eql(false)
        end
      end

      context 'and not all nodes were successful' do
        let(:nodes_body) do
          {
            'succeeded' => ['node1'],
            'failed' => ['node2']
          }
        end

        it 'returns true' do
          expect(subject.failed?).to eql(true)
        end
      end
    end
  end

  describe '#timed_out?' do
    before { mock_job_rest_get }

    context 'when job_status is timed_out' do
      let(:status) { 'timed_out' }
      it 'returns true' do
        subject.refresh
        expect(subject.timed_out?).to eql(true)
      end
    end

    context 'when job status is not timed_out' do
      let(:status) { 'not_timed_out' }
      before do
        allow(subject).to receive(:current_time).and_return(current_time)
        subject.refresh
      end

      context 'but current_time >= start_time + timeout' do
        let(:timeout) { 60 }
        let(:current_time) { DateTime.parse(job['created_at']) + 90 }

        it 'returns true' do
          expect(subject.timed_out?).to eql(true)
        end
      end

      context 'and current_time < start_time + timeout' do
        let(:timeout) { 60 }
        let(:current_time) { DateTime.parse(job['created_at']) + 45 }

        it 'returns false' do
          expect(subject.timed_out?).to eql(false)
        end
      end
    end
  end

  describe '#complete?' do
    before(:each) do
      mock_job_rest_get
      subject.refresh
    end

    let(:push_job_error) { DeliverySugar::Exceptions::PushJobError }

    context 'when job status equals' do
      describe 'new' do
        let(:status) { 'new' }

        it 'returns false' do
          expect(subject.complete?).to eql(false)
        end
      end

      describe 'voting' do
        let(:status) { 'voting' }

        it 'returns false' do
          expect(subject.complete?).to eql(false)
        end
      end

      describe 'running' do
        let(:status) { 'running' }

        it 'returns false' do
          expect(subject.complete?).to eql(false)
        end
      end

      describe 'complete' do
        let(:status) { 'complete' }

        it 'returns true' do
          expect(subject.complete?).to eql(true)
        end
      end

      describe 'quorum_failed' do
        let(:status) { 'quorum_failed' }

        it 'raises PushJobError exception' do
          expect { subject.complete? }.to raise_error(push_job_error)
        end
      end

      describe 'crashed' do
        let(:status) { 'crashed' }

        it 'raises PushJobError exception' do
          expect { subject.complete? }.to raise_error(push_job_error)
        end
      end

      describe 'timed_out' do
        let(:status) { 'timed_out' }

        it 'raises PushJobError exception' do
          expect { subject.complete? }.to raise_error(push_job_error)
        end
      end

      describe 'aborted' do
        let(:status) { 'aborted' }

        it 'raises PushJobError exception' do
          expect { subject.complete? }.to raise_error(push_job_error)
        end
      end
    end
  end
end
