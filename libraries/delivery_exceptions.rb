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
  class Exceptions
    #
    # Raise when a cookbook said to be a cookbook is not a valid cookbook
    #
    class NotACookbook < RuntimeError
      attr_reader :path

      def initialize(path)
        @path = path
      end

      def to_s
        "'#{@path}' is not a valid cookbook"
      end
    end

    #
    # Raise when we fail to upload a cookbook to a Chef Server
    #
    class CookbookUploadFailed < RuntimeError
      def initialize(name, failures)
        @name = name
        @failures = failures
      end

      def to_s
        <<-EOM
Failed to upload #{@name} to the following Chef Servers:
#{chef_server_list}
        EOM
      end

      private

      def chef_server_list
        output = ''
        @failures.each do |server|
          output += "   - #{server}\n"
        end
        output
      end
    end

    #
    # A parent class to handle various different types of PushJob Exceptions
    #
    class PushJobException < RuntimeError
      def initialize(job, msg)
        @job = job
        @msg = msg
      end

      def to_s
        <<-EOM
#{@msg}

Command: #{@job['command']}
Nodes:
#{node_output}
        EOM
      end

      private

      def node_output
        output = ''
        @job['nodes'].each do |status, node_list|
          output += "   #{status}: #{node_list.join(', ')}\n"
        end
        output
      end
    end

    #
    # Raise when a push job completes unsuccessfully
    #
    class PushJobFailed < PushJobException
      def initialize(job)
        msg = "The push-job #{job['id']} failed to complete successfully."
        super(job, msg)
      end
    end

    #
    # Raise when a push job errors out
    #
    class PushJobError < PushJobException
      def initialize(job)
        msg = "The push-job #{job['id']} failed with error state \"#{job['status']}\"."
        super(job, msg)
      end
    end

    #
    # A parent class to handle various different types of PushJob Exceptions
    #
    class PushJobException < RuntimeError
      def initialize(job, msg)
        @job = job
        @msg = msg
      end

      def to_s
        <<-EOM
#{@msg}

Command: #{@job['command']}
Nodes:
#{node_output}
        EOM
      end

      private

      def node_output
        output = ''
        @job['nodes'].each do |status, node_list|
          output += "   #{status}: #{node_list.join(', ')}\n"
        end
        output
      end
    end

    #
    # Raise when a push job completes unsuccessfully
    #
    class PushJobFailed < PushJobException
      def initialize(job)
        msg = "The push-job #{job['id']} failed to complete successfully."
        super(job, msg)
      end
    end

    #
    # Raise when a push job errors out
    #
    class PushJobError < PushJobException
      def initialize(job)
        msg = "The push-job #{job['id']} failed with error state \"#{job['status']}\"."
        super(job, msg)
      end
    end
  end
end
