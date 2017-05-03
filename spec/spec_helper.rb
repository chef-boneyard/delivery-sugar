require 'rspec'
require 'simplecov'
require 'chefspec'
require 'chefspec/berkshelf'

SimpleCov.start if ENV['COVERAGE']

# Set minimum code coverage to 90
SimpleCov.minimum_coverage 90

# SimpleCov Configuration
SimpleCov.profiles.define 'delivery-sugar' do
  add_filter '/spec/support'
  add_filter '/.delivery/'
end

TOPDIR = File.expand_path(File.join(File.dirname(__FILE__), '..'))
SUPPORT_DIR = File.join(TOPDIR, 'spec', 'support')
$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

# Require all our libraries
# We don't require 'z_dsl' here because we need to put assertions in place
# before we require it.
Dir['libraries/delivery_*.rb'].each { |f| require File.expand_path(f) }

# Declare common let declarations
module SharedLetDeclarations
  extend RSpec::SharedContext
  let(:cli_node) do
    {
      'delivery_builder' => {
        'build_user' => 'dbuild'
      },
      'delivery' => {
        'workspace_path' => '/workspace',
        'workspace' => {
          'repo' => '/workspace/path/to/phase/repo',
          'cache' => '/workspace/path/to/phase/cache',
          'chef' => '/workspace/path/to/phase/chef'
        },
        'change' => {
          'stage' => 'stage',
          'enterprise' => 'ent',
          'organization' => 'org',
          'project' => 'proj',
          'change_id' => 'id',
          'pipeline' => 'pipe',
          'patchset_branch' => 'branch',
          'sha' => 'sha'
        }
      }
    }
  end
end

RSpec.configure do |config|
  config.include SharedLetDeclarations
  config.filter_run_excluding 'ignore' => true

  # Specify the operating platform to mock Ohai data from (default: nil)
  config.platform = 'ubuntu'

  # Specify the operating version to mock Ohai data from (default: nil)
  config.version = '12.04'
end
