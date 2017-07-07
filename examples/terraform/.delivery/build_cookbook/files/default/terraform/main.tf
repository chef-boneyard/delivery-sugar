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
