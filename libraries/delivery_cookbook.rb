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
    #
    # @return [DeliverySugar::Cookbook]
    #
    def initialize(cookbook_path)
      @path = cookbook_path
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

    private

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
      metadata = File.join(cookbook_path, 'metadata')
      return load_metadata_rb("#{metadata}.rb") if File.exist?("#{metadata}.rb")
      return load_metadata_json("#{metadata}.json") if File.exist?("#{metadata}.json")
      fail DeliverySugar::Exceptions::NotACookbook(path)
    end

    #
    # Load a metadata.json file
    #
    # @param metadata_json [String]
    #   The fully-qualified path to a metadata.json
    #
    # @return [Chef::Cookbook::Metadata]
    #
    def load_metadata_json(metadata_json)
      metadata = Chef::Cookbook::Metadata.new
      metadata.from_json(File.read(metadata_json))
      metadata
    end

    #
    # For a given metadata.rb file, load the Metadata object from the Chef
    # library.
    #
    # @param metadata_rb [String]
    #   The fully-qualified path to a metadata.rb
    #
    # @return [Chef::Cookbook::Metadata]
    #
    def load_metadata_rb(metadata_rb)
      metadata = Chef::Cookbook::Metadata.new
      metadata.from_file(metadata_rb)
      metadata
    end
  end
end
