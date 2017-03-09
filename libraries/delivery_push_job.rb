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
  # This class is our interface to execute push jobs against a push jobs server.
  #
  class PushJob
    attr_reader :chef_server, :command, :nodes, :job_uri, :job, :quorum

    # Variables for the Job itself
    attr_reader :id, :status, :created_at, :updated_at, :results

    # How long to wait between each refresh during #wait
    PAUSE_SECONDS = 5 unless const_defined?(:PAUSE_SECONDS)

    #
    # Create a new PushJob object
    #
    # @param chef_config_file [String]
    #   The fully-qualified path to a chef config file to load settings from.
    # @param command [String]
    #   The white-listed command to execute via push jobs
    # @param nodes [Array#String]
    #   An array of node names to run the push job against
    # @param timeout [Integer]
    #   How long to wait before timing out
    # @param quorum [Integer]
    #   How many nodes that must acknowledge for the job to run
    #   (default: length of nodes)
    #
    # @return [DeliverySugar::PushJob]
    #
    def initialize(chef_config_file, command, nodes, timeout, quorum = nil)
      fail "[#{self.class}] Expected nodes Array#String" unless valid_node_value?(nodes)
      @command = command
      @nodes = nodes
      @timeout = timeout
      @quorum = quorum || nodes.length
      @chef_server = DeliverySugar::ChefServer.new(chef_config_file)
    end

    #
    # Trigger the push job
    #
    def dispatch
      body = {
        'command' => @command,
        'nodes' => @nodes,
        'run_timeout' => @timeout,
        'quorum' => @quorum
      }

      resp = @chef_server.rest(:post, '/pushy/jobs', {}, body)
      @job_uri = resp['uri']
      refresh
    end

    #
    # Loop until the push job succeeds, errors, or times out.
    #
    def wait
      loop do
        refresh
        fail Exceptions::PushJobFailed, @job if timed_out?
        fail Exceptions::PushJobFailed, @job if failed?
        break if successful?
        pause
      end
    end

    #
    # Return whether or not a push job has completed or not
    #
    # @return [true, false]
    #
    def complete?
      case @status
      when 'new', 'voting', 'running'
        false
      when 'complete'
        true
      else
        fail Exceptions::PushJobError, @job
      end
    end

    #
    # Return whether or not the completed push job was successful.
    #
    # @return [true, false]
    #
    def successful?
      complete? && all_nodes_succeeded?
    end

    #
    # Return whether or not the completed push job failed.
    #
    # @return [true, false]
    #
    def failed?
      complete? && !all_nodes_succeeded?
    end

    #
    # Determine if the push job has been running longer than the timeout
    # would otherwise allow. We do this as a backup to the timeout in the
    # Push Job API itself.
    #
    # @return [true, false]
    #
    def timed_out?
      @status == 'timed_out' || (@created_at + @timeout < current_time)
    end

    #
    # Poll the API for an update on the Job data.
    #
    def refresh
      @job = @chef_server.rest(:get, @job_uri)
      @id ||= job['id']
      @status = job['status']
      @created_at = DateTime.parse(job['created_at'])
      @updated_at = DateTime.parse(job['updated_at'])
      @results = job['nodes']
    end

    private

    #
    # Determine if the nodes are valid node objects
    #
    # @return [true,false]
    #
    def valid_node_value?(nodes)
      nodes == [] || array_of(nodes, String)
    end

    #
    # Return the current time
    #
    # @return [DateTime]
    #
    def current_time
      DateTime.now
    end

    #
    # Return whether or not all nodes are marked as successful.
    #
    # @return [true, false]
    #
    def all_nodes_succeeded?
      @results['succeeded'] && @results['succeeded'].length == @nodes.length
    end

    #
    # Implement our method of pausing before we get the status of the
    # push job again.
    #
    def pause
      sleep PAUSE_SECONDS
    end

    #
    # Validate that an Array is built of an specific `class` kind
    #
    # @param array [Array] The Array to validate
    # @param klass [Class] Class to compare
    #
    # @return [true, false]
    #
    def array_of(array, klass)
      array.any? { |i| i.class == klass }
    end
  end
end
