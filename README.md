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
  path '/path/to/my/cookbook/on/disk/my_cookbook'
  user secrets['supermarket_user']
  key secrets['supermarket_key']
  action :share
end
```

Note that by not specifying the `site` you will be publishing to the Public
Supermarket.

## API

## Test Kitchen

The resource `delivery_test_kitchen` will enable your projects to use [Test Kitchen](http://kitchen.ci)
in Delivery. Currently, we only support the [kitchen-ec2 driver](https://github.com/test-kitchen/kitchen-ec2).

### Prerequisites

In order to enable this functionality, perform the following prerequisite steps:

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

Trigger a kitchen converge & destroy action using Ec2 driver and poiting to `.kitchen.ec2.yml`
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

## Handling Secrets (ALPHA)
This cookbook implements a rudimentary approach to handling secrets. This process
is largely out of band from Chef Delivery for the time being.

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
