require 'spec_helper'
require 'chef/recipe'
require 'chef/resource'
require 'chef/provider'

describe 'z_dsl' do
  # We are explicitly requiring it here because it is not including automatically
  # by our spec_helper. This allows us to put our assertions in place.
  it 'tells Chef::Recipe, Chef::Resource and Chef::Provider to include our DSL' do
    expect(Chef::Recipe).to receive(:include).with(DeliverySugar::DSL)
    expect(Chef::Resource).to receive(:include).with(DeliverySugar::DSL)
    expect(Chef::Provider).to receive(:include).with(DeliverySugar::DSL)
    require_relative '../../libraries/z_dsl.rb'
  end
end
