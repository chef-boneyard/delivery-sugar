# Terraform for Chef Automate Workflow

This is a build_cookbook that demonstrates the use of Terraform in the Provision
phase of the Acceptance stage to instantiate nodes and/or infrastructure in order to test your cookbooks.
It gives you the ability to dynamically provision infrastructure for testing individual cookbooks without
having to maintain long-lived systems.

Note: For [U-R-D](https://docs.chef.io/workflow.html#union-stage) shared pipeline Stages, you likely will want to
employ long-lived nodes that replicate your existing Environment(s).

## The delivery_terraform Resource
`delivery_terraform` is a resource that is provided by the [delivery-sugar](https://github.com/chef-cookbooks/delivery-sugar) cookbook and has these available actions:
* :init
* :plan
* :apply
* :show
* :destroy
* :test

The `delivery_terraform` resource assumes that the consumer installs `terraform` on the runners and provides the plans to be executed (potentially by embedding them in the cookbook under test).

The default action for the resource is `:test` and will run these actions in order: (init, plan, apply, show, destroy)

Exception handling exists to catch errors that may occur during the execution of the `terraform` command and ensure a `terraform destroy` is run to rollback provisioned infrastructure.

### Properties

Property | Type | Required | Suggested Value | Purpose
--- | --- | --- | --- | ---
plan_dir | String | True | "#{delivery_workspace_repo}/.delivery/build_cookbook/files/default/terraform" | Fully qualified path to location of terraform plans

### Example Usage
In addition to having the `terraform` binary installed on the Runners, the `delivery_terraform` requires that you provide your own Plans and secrets management.

```ruby
# recipes/provision.rb

delivery_terraform 'terraform-plans' do
  plan_dir "#{delivery_workspace_repo}/.delivery/build_cookbook/files/default/terraform"
  only_if { workflow_stage?('acceptance') }
end
```
### Accessing the Infrastructure State
After each `delivery_terraform` action, the complete infrastructure state is updated in a ruby hash within `node.run_state['terraform-state']`

### Supported Versions
This has been tested with Terraform `0.9.8`

### Remote State
Terraform uses a state store (by default a local file: terraform.tfstate) to keep track of changes made to infrastructure.

If you have more than one runner, you may consider using one of Terraform's remote [Backends](https://www.terraform.io/docs/backends/index.html) that implement [Remote State](https://www.terraform.io/docs/state/remote.html) to ensure that multiple runners share the same saved state context.  There are multiple [Backend Types](https://www.terraform.io/docs/backends/types/index.html) available.

An [example](https://www.terraform.io/docs/backends/types/etcd.html) Terraform plan config section that uses `etcd` for remote state sharing:
```js
# main.tf

data "terraform_remote_state" "foo" {
  backend = "etcd"
  config {
    path      = "path/to/terraform.tfstate"
    endpoints = "http://one:4001 http://two:4001"
  }
}
```

Note: if all Phase actions can be encapsulated in your Terraform Plans and executed in a single Workflow Phase (such as Provision), Remote State usage may not be required
as only a single Runner will ever execute actions.

The `terraform init` command is always the first command run by the `delivery_terraform` resource to ensure that the remote state you configured is set up and initialized.

## Terraform Installation on Runners
The `default` recipe runs as root and executes first in each Workflow Stage, prior to the other Phases.  It can easily handle the installation of the `terraform` binary on the runner.  One simple method to install terraform is via the [terraform](https://github.com/rosstimson/chef-terraform) cookbook.
```ruby
# recipes/default.rb
#
# Cookbook:: build_cookbook
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.
include_recipe 'delivery-truck::default'

node.default['terraform']['version'] = '0.9.8'
include_recipe 'terraform'
```

The `terraform` cookbook is declared as a dependency in `metadata.rb` and downloaded via your configured source in `Berksfile` (by default Chef Supermarket):
```ruby
# metadata.rb
name 'build_cookbook'
maintainer 'The Authors'
maintainer_email 'you@example.com'
license 'all_rights'
version '0.1.0'
chef_version '>= 12.1' if respond_to?(:chef_version)

depends 'terraform'
depends 'delivery-truck'
```

## Terraform Plan Files
Terraform will use plan files passed as a command line option.  These files are your infrastructure-as-code.  The `delivery_terraform` requires a `plan_dir` property in order to access the plans.  Terraform will automatically read any files ending in `.tf`.

You can therefore bundle plan files within the build_cookbook and pass in the location of the directory via `plan_dir`.

You should validate that your plans are valid and work correctly first, before running them through your pipeline.

```js
# Example location: files/default/terraform/main.tf

data "template_file" "dna" {
  template = "${file("dna.json.tpl")}"
  vars {
    attribute1 = "value1"
    attribute2 = "value2"
    recipe = "my_cookbook::default"
  }
}

provider "openstack" {
  user_name   = "${var.user_name}"
  tenant_name = "${var.tenant_name}"
  password    = "${var.password}"
  auth_url    = "https://iad2.dream.io:5000/v2.0"
}

resource "openstack_compute_instance_v2" "terraform" {
  name = "terraform"
  count = 1
  image_name = "${var.image_name}"
  flavor_name = "${var.flavor_name}"
  key_pair = "${var.key_pair}"
  network {
    name = "public"
  }

  connection {
    user     = "${var.user}"
    private_key = "${var.private_key}"
  }

  provisioner "local-exec" {
    command = "berks package --berksfile=./Berksfile && mv cookbooks-*.tar.gz cookbooks.tar.gz"
  }

  provisioner "file" {
    source      = "cookbooks.tar.gz"
    destination = "/tmp/cookbooks.tar.gz"
  }

  provisioner "file" {
    content = "${data.template_file.dna.rendered}"
    destination = "/tmp/dna.json"
  }

  provisioner "remote-exec" {
    inline = [
      "curl -LO https://www.chef.io/chef/install.sh && sudo bash ./install.sh",
      "sudo chef-solo --recipe-url /tmp/cookbooks.tar.gz -j /tmp/dna.json"
    ]
  }
}
```

A json file can be used and passed to `chef-solo` to control attributes and the run_list during the ephemeral node converge.

```json
# Example location: files/default/terraform/dna.json.tpl
{
    "my_cookbook": {
        "attribute1": "${attribute1}",
        "attribute2": "${attribute2}"
    },
    "run_list": [
        "recipe[${recipe}]"
    ]
}
```

### Secrets
You will NOT want to check plan files containing plain text secrets into version control.

One option is to use Terraform variables as shown below where the values can be set in [ENVIRONMENT](https://www.terraform.io/docs/configuration/variables.html#environment-variables) variables which will automatically be populated by Terraform.

```js
# main.tf

variable "user_name" {}
variable "private_key" {}

connection {
  user     = "${var.user_name}"
  private_key = "${var.private_key}"
}
```

In order to keep the secrets secure, you may consider using `delivery-sugar` DSL for [Handling Secrets](https://github.com/chef-cookbooks/delivery-sugar#handling-secrets-alpha) then retrieve the values and set environment variables that Terraform will read.

Then, in the provision recipe you could populate your `TV_VAR_xxxx` ENV variables via your secrets source.

Note: By settting the variables via ruby's `ENV` Class and NOT via Chef's `env` resource, the values will only exist for the duration of the current run context and then will be discarded.

```ruby
# recipes/provision.rb

include_recipe 'delivery-truck::provision'

vault_data = get_chef_vault_data

# merge in your secrets into the current Environment context
# they will be discared when the run is finished
ENV.update(
  'TF_VAR_user_name'     => vault_data['openstack-user_name'],
  'TF_VAR_tenant_name'   => vault_data['openstack-tenant_name'],
  'TF_VAR_password'      => vault_data['openstack-password'],
  'TF_VAR_key_pair'      => vault_data['openstack-key_pair'],
  'TF_VAR_private_key'   => vault_data['openstack-private_key']
)

delivery_terraform 'terraform-plan' do
  # provide the full path to the location of plans directory
  plan_dir "#{delivery_workspace_repo}/.delivery/build_cookbook/files/default/terra_plans"
  only_if { workflow_stage?('acceptance') }
end
```

### Integration Tests
Running [Inspec](https://github.com/chef/inspec) integration or compliance tests on your ephemeral nodes is a great way to ensure your cookbook code behaved as expected and didn't introduce any security concerns.

You could install `inspec` on the ephemeral node as a `remote-exec`, then utilizing inspec tests can then be as simple as running a scan using a Compliance profile from a remote source.
```js
# main.tf

provisioner "remote-exec" {
  inline = [
     "sudo chef gem install inspec",
     "sudo inspec exec https://github.com/dev-sec/tests-os-hardening/archive/master.zip"
  ]
}
```

Additionally, if you wish to run the parent cookbook's integration tests from `test/smoke/default/default_test.rb`
```ruby
# recipes/provision.rb

ENV.update(
  'TF_VAR_runner_inspec_tests_path'     =>  "#{delivery_workspace_repo}/test/smoke/default",
  ...
)
```

```js
# main.tf example of running tests from parent cookbook

variable "runner_inspec_tests_path" {}

provisioner "local-exec" {
  command = "tar cvzf inspec_tests.tar.gz ${var.runner_inspec_tests_path}"
}

provisioner "file" {
  source      = "inspec_tests.tar.gz"
  destination = "/tmp/inspec_tests.tar.gz"
}

provisioner "remote-exec" {
  inline = [
    "inspec exec /tmp/inspec_tests.tar.gz"
  ]
}
```
