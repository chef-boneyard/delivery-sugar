# delivery-sugar

Delivery Sugar is a library cookbook that includes a collection of helpful
sugars and custom resources that make creating build cookbooks for Chef
Delivery projects a delightful experience.

## Installation

If you are using Berkshelf, add `delivery-sugar` to your `Berksfile`:

    cookbook 'delivery-sugar'


## Usage

In order to use Delivery Sugar in your build cookbook recipes, you'll first
need to declare your dependency on it in your `metadata.rb`.

    depends 'delivery-sugar'

Declaring your dependency will automatically extend the Recipe DSL,
`Chef::Resource` and `Chef::Provider` with helpful methods. It will also
automatically make available the custom resources included with Delivery Sugar.

**There is no need to include Delivery Sugar in any of your recipes**

## DSL

The following are DSL helper methods available to you when you include
Delivery Sugar in your build cookbook.

### Automate Helpers
Helpers that can assist you in detecting and communicating with the larger
Automate environment.

#### `automate_knife_rb`
The path to the knife config that can communicate with the Automate Chef Server.
**Default Value:** `/var/opt/delivery/workspace/.chef/knife.rb`

#### `automate_chef_server_details`
Cheffish details you can pass into Provisioning or Cheffish resources (i.e
`chef_environment`).

#### `build_user`
The name of the local user executing the job (e.g. `dbuild`).

### Workspace Details
Helpers that provide the paths to the relevant workspace directories on the
build node.

#### `workflow_workspace`
The path to the shared workspace on the Build Nodes. This workspace is shared
across all organizations and projects. In this directory are things like
builder keys, ssh wrappers, etc. **Default Value:** `/var/opt/delivery/workspace`

#### `workflow_workspace_repo`
The path to the root of your project's code repository on the the build node.

#### `workflow_workspace_chef`
The path to the directory where the chef-client run associated with the phase
job is executed from.

#### `workflow_workspace_cache`
The path to a cache directory associated with this phase run.

#### `workflow_workspace_root`
The parent directory of repo, chef, and cache.

### Pipeline Details

#### `workflow_stage`
The name of the stage currently being executed (i.e. verify, build, etc).

#### `workflow_phase`
The name of the phase currently being executed (i.e. unit, lint, etc)

#### `workflow_chef_environment_for_stage`
The name of the Chef Environment associated with the current stage.

#### `workflow_project_acceptance_environment`
The name of the Chef Environment associated with the Acceptance stage for this
project.

### Change Details
Details that are specific to the current change.

#### `workflow_change_enterprise`
The name of the Automate enterprise associated with the change.

#### `workflow_change_organization`
The name of the Automate organization associated with the change.

#### `workflow_change_project`
The name of the Automate project associated with the change.

#### `workflow_change_pipeline`
The name of the Automate pipeline associated with the change.

#### `workflow_change_id`
The Change ID associated with the current phase run.

#### `workflow_change_merge_sha`
The merge SHA associated with the current change. Will be `null` for phases in
the Verify stage.

#### `workflow_change_patchset_branch`
The name of the branch originally given to the change when it was submitted
for review.

#### `changed_cookbooks`
Returns an array of `DeliverySugar::Cookbook` objects for each cookbook that
was modified in the current change.

#### `changed_files`
Returns a list of all the files modified in the current change. File names are
scoped to the project root.

#### `changed_dirs`
Returns a list of all the directories modified in the current change. Optionally
provide an integer to specify the desired directory depth.

#### `change_log`
Returns a list of commits from the SCM log in reverse chronological order.

#### `workflow_project_slug`
Returns a unique string that can be used to identify the current project.

**Format:** `<ENTERPRISE>-<ORGANIZATION>-<PROJECT>`

#### `workflow_organization_slug`
Returns a unique string that can be used to identify the organization associated
with the current project.

**Format:** `<ENTERPRISE>-<ORGANIZATION>`

#### `workflow_enterprise_slug`
Returns a unique string that can be used to identify the current enterprise.
**Format:** `<ENTERPRISE>`

## Running against the Automate Chef Server
Sometimes you need to perform actions in your build cookbook as though it was
running against a Chef Server. To do this, you can use the `with_server_config`
DSL. Behind the scenes, during the compile phase of the chef client run, we
temporarily modify the `Chef::Config` object to point towards Automate's Chef
Server. Here's an example of us running a node search against the Automate
Chef Server to find a specific node.

```ruby
with_server_config do
  search(:node, 'role:web',
    :filter_result => { 'name' => [ 'name' ],
                        'ip' => [ 'ipaddress' ],
                        'kernel_version' => [ 'kernel', 'version' ]
                      }
        ).each do |result|
    puts result['name']
    puts result['ip']
    puts result['kernel_version']
  end
end
```

We have noticed that in some use cases, the `with_server_config` DSL does not
work for some users because `with_server_config` only modifies the `Chef::Config`
object during the initial compilation of the resource collection, not
during the execution phase. If you run into issues with things like `automate_chef_server_details`
not working for you, you may need to use the DSL `run_recipe_against_automate_chef_server`
instead. Rather than restoring the initial `Chef::Config` after compilation,
`run_recipe_against_automate_chef_server` leaves the `Chef::Config` object configured
with the Automate Chef Server details for the entire chef run. We strongly
encourage that you use `run_recipe_against_automate_chef_server` _only_ as a last resort.

## Resource `delivery_supermarket`

With this new resource you can easily share your cookbook to Supermarket
by just calling:
```ruby
delivery_supermarket 'share_cookbook' do
  site 'https://my-private-supermarket.example.com'
end
```

That will take all the defaults from Delivery. It means that if you are
sharing a cookbook to your Private Supermarket it will use the `delivery`
credentials that the cluster is linked to.

If you want to customize your resource you can use more attributes:
```ruby
secrets = get_project_secrets
delivery_supermarket 'share_custom_cookbook' do
  config '/path/to/my/knife.rb'
  cookbook 'my_cookbook'
  category 'Applications'
  path '/path/to/my/cookbook/on/disk/my_cookbook'
  user secrets['supermarket_user']
  key secrets['supermarket_key']
  action :share
end
```

Note that by not specifying the `site` you will be publishing to the Public
Supermarket.

Find a list of available categories [here](https://docs.chef.io/plugin_knife_supermarket.html#share).

## Terraform
The resource `delivery_terraform` will allow your projects to use [Terraform](https://www.terraform.io)
in order to provision ephemeral nodes.

More on that topic [here](examples/terraform/.delivery/build_cookbook/README_TERRAFORM.md)

## Test Kitchen

The resource `delivery_test_kitchen` will enable your projects to use [Test Kitchen](http://kitchen.ci)
in Delivery. Currently, we only support the [kitchen-ec2 driver](https://github.com/test-kitchen/kitchen-ec2) and  [kitchen-azurerm](https://github.com/pendrica/kitchen-azurerm) drivers.

### Prerequisites

In order to enable this functionality, perform the following prerequisite steps:

#### EC2

* Add the following items to the appropriate data bag as specified in the [Handling Secrets](#handling-secrets-alpha) section

    **delivery-secrets <ent>-<org>-<project> encrypted data bag item**
    ```json
    {
      "id": "<ent>-<org>-<project>",
      "ec2": {
        "access_key": "<ec2-access-key>",
        "secret_key": "<ec2-secret-key>",
        "keypair_name": "<ec2-keypair-name>",
        "private_key": "<JSON-compatible-ec2-keypair-private-key-content>"
       }
     }
    ```
    You can convert the private key content to a JSON-compatible string with a command like this:
    ```
    ruby -e 'require "json"; puts File.read("<path-to-ec2-private-key>").to_json'
    ```

* Customize your kitchen YAML file with all the required information needed by the [kitchen-ec2 driver](https://github.com/test-kitchen/kitchen-ec2) driver. delivery-sugar will expose the following ENV variabls for use by kitchen:
  * `KITCHEN_INSTANCE_NAME` - set to the `<project-name>-<change-id>` values provided by [delivery-cli](https://github.com/chef/delivery-cli#change-details)
  * `KITCHEN_EC2_SSH_KEY_PATH` - path to the SSH private key created from the delivery-secrets data bag

    These variables may be used in your kitchen YAML like the following example:

    ```yaml
    ---
    driver:
      name: ec2
      region: us-west-2
      availability_zone: a
      instance_type: t2.micro
      image_id: ami-5189a661
      subnet_id: subnet-19ac017c
      tags:
        Name: <%= ENV['KITCHEN_INSTANCE_NAME'] || 'delivery-kitchen-instance' %>

    transport:
      ssh_key: <%= ENV['KITCHEN_EC2_SSH_KEY_PATH'] %>

    provisioner:
      name: chef_zero

    platforms:
      - name: ubuntu-14.04

    suites:
      - name: default
        run_list:
          - recipe[test-build-cookbook::default]
        attributes:

    ```

#### Azure

Ensure you have set up a Service Principal in Azure according to the [kitchen-azurerm README](https://github.com/pendrica/kitchen-azurerm/blob/master/README.md)

Additionally at this point, installing the `kitchen-azurerm` requires build tools on the build nodes. You will need to customize your build cookbook as follows:

  1. Add `depends 'build-essential', '~> 7.0.2'` to the `metadata.rb` of the build cookbook.
  2. Add `include_recipe 'build-essential::default'` to the `default.rb` of the build cookbook.

* Add the following items to the appropriate data bag as specified in the [Handling Secrets](#handling-secrets-alpha) section

    **delivery-secrets <ent>-<org>-<project> encrypted data bag item**
    ```json
    {
      "id": "<ent>-<org>-<project>",
      "azure": {
        "subscription_id": "<YOUR-SUBSCRIPTION-ID-HERE>",
        "client_id": "<48b9bba3-YOUR-GUID-HERE-90f0b68ce8ba>",
        "client_secret": "<your-client-secret-here>",
        "tenant_id": "<9c117323-YOUR-GUID-HERE-9ee430723ba3>"
       }
     }
    ```

  * Customize your kitchen YAML file with all the required information needed by the [kitchen-azurerm driver](https://github.com/pendrica/kitchen-azurerm) driver. For example:

        ```yaml
        ---
        driver:
          name: azurerm

        driver_config:
          subscription_id: 'YOUR-SUBSCRIPTION-ID-HERE'
          location: 'West Europe'
          machine_size: 'Standard_D1'

        transport:
          ssh_key: ~/.ssh/id_kitchen-azurerm

        provisioner:
          name: chef_zero

        verifier:
          name: inspec

        platforms:
          - name: ubuntu-14.04
            driver_config:
              image_urn: Canonical:UbuntuServer:14.04.4-LTS:latest
              vm_name: trusty-vm

        suites:
          - name: default
            run_list:
              - recipe[azure_test::default]
            verifier:
              inspec_tests:
                - test/recipes
            attributes:

        ```


### Usage

Once you have the prerequisites you can use `delivery_test_kitchen` anywhere in your project pipeline, you
just need to call the resource within your build-cookbook of your project.

#### Examples

Trigger a kitchen test using Ec2 driver

```ruby
delivery_test_kitchen 'functional_test' do
  driver 'ec2'
end
```

Trigger a kitchen converge & destroy action using Ec2 driver and pointing to `.kitchen.ec2.yml`
file inside the repository path in Delivery.

```ruby
delivery_test_kitchen 'quality_converge_destroy' do
  yaml '.kitchen.ec2.yml'
  driver 'ec2'
  repo_path delivery_workspace_repo
  action [:converge, :destroy]
end
```

Trigger a kitchen create passing extra options for debugging

```ruby
delivery_test_kitchen 'unit_create' do
  driver 'ec2'
  options '--log-level=debug'
  suite 'default'
  action :create
end
```

Trigger a kitchen create extending the timeout to 20 minutes

```ruby
delivery_test_kitchen 'unit_create' do
  driver 'ec2'
  suite 'default'
  timeout 1200
  action :create
end
```

#### Docker

You can leverage the [kitchen-dokken](https://github.com/someara/kitchen-dokken) driver in your tests
as well. This does not require the use of `delivery-secrets`. To enable `kitchen-dokken`, do the following to
install Docker on all of your builders/runners:

Add `depends 'docker', '~> 2.0'` to the `metadata.rb` of the build cookbook.
Add the following code to the `default.rb` of the build cookbook:

```ruby
docker_service 'default' do
  action [:create, :start]
end

group 'docker' do
  action :modify
  members 'dbuild'
  append true
end
```

## InSpec

The resource `delivery_inspec` will enable your projects to run any [InSpec](https://inspec.io) tests in the cookbook against your nodes in Acceptance, Union, Rehearsal, or Delivered. Currently, we only support running tests against Linux or Windows nodes.

### Prerequisites

In order to enable this functionality, perform the following prerequisite steps:

* Add the following items to the appropriate data bag as specified in the [Handling Secrets](#handling-secrets-alpha) section

    **delivery-secrets <ent>-<org>-<project> encrypted data bag item**
    ```json
    {
      "id": "<ent>-<org>-<project>",
      "inspec": {
        "ssh-user": "inspec",
        "ssh-private-key": "<YOUR-PRIVATE-KEY-HERE",
        "winrm-user": "inspec",
        "winrm-password": "<YOUR-PASSWORD-HERE>"
      }
     }
    ```
    You can convert the private key content to a JSON-compatible string with a command like this:
    ```
    ruby -e 'require "json"; puts File.read("<path-to-inspec-private-key>").to_json'
    ```

* Ensure that the associated user for either `ssh-user` or `winrm-user` exists on the nodes to be tested, with either the public key added to `authorized_keys`(if Linux), or the password set (if Windows). The associated user must either have passwordless sudo, or be in the Administrators group (if Windows).

Note that the `delivery_inspec` resource also supports "organization-level" data bag items, so the above item could also be set at `"id": "<ent>-<org>"`.

Trigger InSpec testing as follows

```ruby
search_query = "recipes:#{node['delivery']['change']['project']}* AND " \
"chef_environment:#{delivery_environment}"
nodes = delivery_chef_server_search(:node, search_query.to_s)

nodes.each do |i_node|
  delivery_inspec "inspec_#{node['delivery']['change']['project']}" do
    infra_node i_node['ipaddress']
    os i_node['os']
  end
end
```
The default value for tests are in the `test/recipes` directory of your cookbook, but you can over-ride it with the optional `inspec_test_path` parameter. For example:

```ruby
delivery_inspec "run_inspec" do
  infra_node '10.0.0.1'
  os 'windows'
  inspec_test_path 'test/smoke'
end
```

## Handling Secrets (ALPHA)
This cookbook implements a rudimentary approach to handling secrets. This process
is largely out of band from Chef Automate for the time being.

### Using `get_project_secrets`
Your build cookbook will look for secrets in the `delivery-secrets` data bag on the
Delivery Chef Server. It will expect to find an item in that data bag named
`<ent>-<org>-<project>`. For example, lets imagine a cookbook called 'delivery-test'
that is kept in the 'open-source' org of the 'chef' enterprise so it's data bag name
would be `chef-open-source-delivery-test`.

This cookbook expects this data bag item to be encrypted with the same
encrypted_data_bag_secret that is on your builders. You will need to ensure that
the data bag is available on the Chef Server before you run this cookbook for
the first time otherwise it will fail.

To get this data bag you can use the DSL `get_project_secrets` to get the
contents of the data bag.

```
my_secrets = get_project_secrets
puts my_secrets['id'] # chef-Delivery-Build-Cookbooks-delivery-truck
```

If the project item does not exist, delivery-sugar will try to load the secrets
of the organization that your project lives in. It will look for an item called
`<ent>-<org>`. For the same example above it would be `chef-open-source`. This is
useful if you would like to share secrets across projects within the same organization.

### Using `get_chef_vault_data`
Using the DSL method `get_chef_vault_data` will return a merged Ruby hash from the
Chef Vaults in `workflow-vaults` on your Automate Chef Server.

In order to use this DSL method you must use the following naming standard for your
Chef Vault items under the `workflow_vaults` vault:

  - `#{ent_name}`
  - `#{ent_name}-#{org_name}`
  - `#{ent_name}-#{org_name}-#{project_name}`

The data in these vaults will be merged into a single Ruby hash. Any duplicate key
names will be merged as follows:
  - `#{ent_name}-#{org_name}-#{project_name}` will overwrite `#{ent_name}-#{org_name}` and `#{ent_name}`.
  - `#{ent_name}-#{org_name}` will overwrite `#{ent_name}`.

You can access the data like so:

```
vault_data = get_chef_vault_data
puts vault_data['my_key']
```

Example Creation of the `workflow_vaults` Chef Vault and a vault item for the following:
 - Workflow Enterprise: `brewinc`
 - Workflow Organization: `breworg`
 - Workflow Project: `mysql-server`

```bash
$ cat tmp/secrets.json
{
  "id": "brewinc-breworg-mysql-server",
  "openstack-password": "secret-password"
}
$ knife vault create workflow-vaults brewinc-breworg-mysql-server -S "name:automate_runner**" -A "delivery,admin" -J tmp/secrets.json -M client
```

_NOTE: We recommend to have always the latest version of ChefDK installed on your Runners._

## License & Authors
- Author:: Tom Duffield (<tom@chef.io>)
- Author:: Jon Anderson (<janderson@chef.io>)
- Author:: Matt Campbell (<mcampbell@chef.io>)
- Author:: Salim Afiune (<afiune@chef.io>)

```text
Copyright:: 2015 Chef Software, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
