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

require 'pathname'

module DeliverySugar
  #
  # This class will represent a Chef Cookbook and provide information and
  # helper functions based on use cases for Delivery recipes.
  #
  class Cookbook
    attr_reader :path, :version, :name

    #
    # Create a new Cookbook object
    #
    # @param cookbook_path [String]
    #   The fully-qualified path to the cookbook on disk
    # @param read_file [lambda]
    #   A function that can take a file path and return file contents
    #   if it exists or nil otherwise. If this is not provided,
    #   default file system calls are made.
    #
    # @return [DeliverySugar::Cookbook]
    #
    def initialize(cookbook_path, read_file = nil)
      @path = cookbook_path
      @read_file = read_file
      metadata = load_metadata(cookbook_path)
      @version = metadata.version
      @name = metadata.name
    end

    #
    # Determine if two Cookbook objects are equal
    #
    # @param other [DeliverySugar::Cookbook]
    #   The Cookbook object we are comparing against.
    #
    # @return [true, false]
    #
    def ==(other)
      (@name == other.name) &&
        (@path == other.path) &&
        (@version == other.version)
    end
    alias eql? ==

    #
    # Return the hash of the object (for equality checking)
    #
    # @return [Fixnum]
    #
    def hash
      state.hash
    end

    private

    #
    # Returns the contents of a file at the given path
    #
    # @return [String] file contents or nil if path is unreadable.
    #
    def file_contents(path)
      if @read_file
        @read_file[path]
      elsif File.exist?(path)
        File.read(path)
      end
    end

    #
    # Load the metadata for a given cookbook path
    #
    # @param cookbook_path [String]
    #   The fully-qualified path for a cookbook
    #
    # @raise [DeliverySugar::Exceptions::NotACookbook]
    #   If the given path is not a cookbook
    #
    # @return [Chef::Cookbook::Metadata]
    #
    def load_metadata(cookbook_path)
      metadata_path = File.join(cookbook_path, 'metadata')
      metadata = Chef::Cookbook::Metadata.new

      contents = file_contents("#{metadata_path}.rb")
      unless contents.nil?
        # Currently, Metadata does not have a way to load ".rb" files
        # directly from a string containing the code to be evaluated.
        # So we follow the general strategy used in:
        # https://github.com/chef/chef/blob/master/lib/chef/mixin/from_file.rb
        #
        # We provide the contents directly and give the file name and 1
        # (for the line number) to evaluate the .rb file in the context of the
        # metadata object.
        metadata.instance_eval(contents, "#{metadata_path}.rb", 1)
        return metadata
      end

      contents = file_contents("#{metadata_path}.json")
      return metadata.from_json(contents) unless contents.nil?

      fail DeliverySugar::Exceptions::NotACookbook, cookbook_path
    end

    #
    # The state of the object (used for hash)
    #
    # @return [Array<String>]
    #
    def state
      [@name, @version, @path]
    end
  end
end
