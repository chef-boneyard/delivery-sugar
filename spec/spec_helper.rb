require 'rspec'
require 'simplecov'

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
