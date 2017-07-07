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
# rubocop:disable Metrics/LineLength
if defined?(ChefSpec)
  ChefSpec.define_matcher :delivery_push_job
  def dispatch_delivery_push_job(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:delivery_push_job, :dispatch, resource_name)
  end

  ChefSpec.define_matcher :delivery_supermarket
  def share_delivery_supermarket(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:delivery_supermarket, :share, resource_name)
  end

  ChefSpec.define_matcher :delivery_github
  def push_delivery_github(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:delivery_github, :push, resource_name)
  end

  ChefSpec.define_matcher :delivery_chef_cookbook
  def upload_delivery_chef_cookbook(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:delivery_chef_cookbook, :upload, resource_name)
  end

  ChefSpec.define_matcher :delivery_test_kitchen
  def create_delivery_test_kitchen(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:delivery_test_ktichen, :create, resource_name)
  end

  def converge_delivery_test_kitchen(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:delivery_test_kitchen, :converge, resource_name)
  end

  def setup_delivery_test_kitchen(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:delivery_test_kitchen, :setup, resource_name)
  end

  def verify_delivery_test_kitchen(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:delivery_test_kitchen, :verify, resource_name)
  end

  def destroy_delivery_test_kitchen(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:delivery_test_kitchen, :destroy, resource_name)
  end

  def test_delivery_test_kitchen(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:delivery_test_kitchen, :test, resource_name)
  end

  def init_delivery_terraform(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:delivery_terraform, :init, resource_name)
  end

  def plan_delivery_terraform(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:delivery_terraform, :plan, resource_name)
  end

  def apply_delivery_terraform(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:delivery_terraform, :apply, resource_name)
  end

  def show_delivery_terraform(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:delivery_terraform, :show, resource_name)
  end

  def destroy_delivery_terraform(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:delivery_terraform, :destroy, resource_name)
  end

  def test_delivery_terraform(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:delivery_terraform, :test, resource_name)
  end
end
