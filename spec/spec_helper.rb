require 'rspec'

TOPDIR = File.expand_path(File.join(File.dirname(__FILE__), ".."))
$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

# Require all our libraries
Dir['libraries/*.rb'].each { |f| require File.expand_path(f) }
