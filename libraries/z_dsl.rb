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

# This file is named z_dsl to take advantage of Chef's method of loading library
# files. By loading this file last, the rest of the required libraries will
# have already been loaded removing the need to require them each individually.

# By including this file, the DSL exposed by DeliverySugar will be made available
# in your Chef Recipes, Resources and Providers.

# In general, the way we are doing this (using .send) is a bad idea because in
# other places easily cause naming collisions. However, because delivery-sugar
# is only intended to run inside Delivery Phase Runs, the risk of method naming
# collissions is lessened.

Chef::Recipe.send(:include, DeliverySugar::DSL)
Chef::Resource.send(:include, DeliverySugar::DSL)
Chef::Provider.send(:include, DeliverySugar::DSL)
