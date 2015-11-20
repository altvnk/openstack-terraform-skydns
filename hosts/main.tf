variable datacenter             { default = "openstack" }
variable master_flavor          {}
variable node_flavor            {}
variable keypair_name           {}
variable image_name             {}
variable master_count           {}
variable node_count             {}
variable security_groups        {}
variable floating_pool          {}
variable external_net_id        {}
variable subnet_cidr            {}
variable ip_version             { default = "4" }
variable short_name             { default = "vm" }
variable long_name              { default = "example" }
variable ssh_user               { default = "centos" }
variable docker_master_volume   { default = 10 }
variable docker_node_volume     { default = 20 }
variable dns_domain             { default = "example.com" }
variable dns_nameservers        {}
variable dns_flavor             {}
variable dns_image_name         {}

resource "template_file" "cloud-init-dns" {
  filename      = "templates/user-data-dns.yaml"
  vars {
    hostname    = "${ var.short_name }-ns }"
    domain      = "${ var.dns_domain }"
  }
}

resource "template_file" "cloud-init-master" {
  count         = "${ var.master_count }"
  filename      = "templates/user-data.yaml"
  vars {
    hostname    = "${ var.short_name }-master-${ format("%02d", count.index+1) }"
    domain      = "${ var.dns_domain }"
    nameservers = "${ var.dns_nameservers }"
  }
}

resource "template_file" "cloud-init-node" {
  count         = "${ var.node_count }"
  filename      = "templates/user-data.yaml"
  vars {
    hostname    = "${ var.short_name }-node-${ format("%02d", count.index+1) }"
    domain      = "${ var.dns_domain }"
    nameservers = "${ var.dns_nameservers }"
  }
}

resource "openstack_blockstorage_volume_v1" "master-volume" {
  name          = "${ var.short_name }-master-${format("%02d", count.index+1) }"
  description   = "${ var.short_name }-master-${format("%02d", count.index+1) }"
  size          = "${ var.docker_master_volume }"
  count         = "${ var.master_count }"
}

resource "openstack_blockstorage_volume_v1" "node-volume" {
  name          = "${ var.short_name }-node-${format("%02d", count.index+1) }"
  description   = "${ var.short_name }-node-${format("%02d", count.index+1) }"
  size          = "${ var.docker_node_volume }"
  count         = "${ var.node_count }"
}

resource "openstack_compute_instance_v2" "dns" {
  floating_ip           = "${ openstack_compute_floatingip_v2.dns-floatip.address }"
  name                  = "${ var.short_name}-ns.${ var.dns_domain }"
  key_pair              = "${ var.keypair_name }"
  image_name            = "${ var.dns_image_name }"
  flavor_name           = "${ var.dns_flavor }"
  security_groups       = [ "${ var.security_groups }", "default" ]
  network               = {
                            uuid        = "${ openstack_networking_network_v2.network.id }"
                            fixed_ip_v4 = "${ var.dns_nameservers }"
                          }
  metadata              = {
                            role        = "dns"
                            ssh_user    = "core"
                          }
  user_data             = "${ template_file.cloud-init-dns.rendered }"
}

resource "openstack_compute_instance_v2" "master" {
  floating_ip           = "${ element(openstack_compute_floatingip_v2.master-floatip.*.address, count.index) }"
  name                  = "${ var.short_name}-master-${format("%02d", count.index+1) }.${ var.dns_domain }"
  key_pair              = "${ var.keypair_name }"
  image_name            = "${ var.image_name }"
  flavor_name           = "${ var.master_flavor }"
  security_groups       = [ "${ var.security_groups }", "default" ]
  network               = { uuid        = "${ openstack_networking_network_v2.network.id }" }
  volume                = {
                            volume_id   = "${ element(openstack_blockstorage_volume_v1.master-volume.*.id, count.index) }"
                            device      = "/dev/vdb"
                          }
  metadata              = {
                            dc          = "${ var.datacenter }"
                            role        = "master"
                            ssh_user    = "${ var.ssh_user }"
                          }
  count                 = "${ var.master_count }"
  user_data             = "${ element(template_file.cloud-init-master.*.rendered, count.index) }"
  depends_on            = "openstack_compute_instance_v2.dns"
}

resource "openstack_compute_instance_v2" "node" {
  floating_ip           = "${ element(openstack_compute_floatingip_v2.node-floatip.*.address, count.index) }"
  name                  = "${ var.short_name}-node-${format("%02d", count.index+1) }.${ var.dns_domain }"
  key_pair              = "${ var.keypair_name }"
  image_name            = "${ var.image_name }"
  flavor_name           = "${ var.node_flavor }"
  security_groups       = [ "${ var.security_groups }", "default" ]
  network               = { uuid        = "${ openstack_networking_network_v2.network.id }" }
  volume                = {
                            volume_id   = "${ element(openstack_blockstorage_volume_v1.node-volume.*.id, count.index) }"
                            device      = "/dev/vdb"
                          }
  metadata              = {
                            dc          = "${ var.datacenter }"
                            role        = "node"
                            ssh_user    = "${ var.ssh_user }"
                          }
  count                 = "${ var.node_count }"
  user_data             = "${ element(template_file.cloud-init-node.*.rendered, count.index) }"
  depends_on            = "openstack_compute_instance_v2.dns"
}

resource "openstack_compute_floatingip_v2" "dns-floatip" {
  pool          = "${ var.floating_pool }"
  depends_on    = [ "openstack_networking_router_v2.router",
                    "openstack_networking_network_v2.network",
                    "openstack_networking_router_interface_v2.router-interface" ]
}

resource "openstack_compute_floatingip_v2" "master-floatip" {
  pool          = "${ var.floating_pool }"
  count         = "${ var.master_count }"
  depends_on    = [ "openstack_networking_router_v2.router",
                    "openstack_networking_network_v2.network",
                    "openstack_networking_router_interface_v2.router-interface" ]
}

resource "openstack_compute_floatingip_v2" "node-floatip" {
  pool          = "${ var.floating_pool }"
  count         = "${ var.node_count }"
  depends_on    = [ "openstack_networking_router_v2.router",
                    "openstack_networking_network_v2.network",
                    "openstack_networking_router_interface_v2.router-interface" ]
}

resource "openstack_networking_network_v2" "network" {
  name              = "${ var.short_name }-network"
}

resource "openstack_networking_subnet_v2" "subnet" {
  name              = "${ var.short_name }-subnet"
  network_id        = "${ openstack_networking_network_v2.network.id }"
  cidr              = "${ var.subnet_cidr }"
  ip_version        = "${ var.ip_version }"
}

resource "openstack_networking_router_v2" "router" {
  name              = "${ var.short_name }-router"
  external_gateway  = "${ var.external_net_id }"
}

resource "openstack_networking_router_interface_v2" "router-interface" {
  router_id         = "${ openstack_networking_router_v2.router.id }"
  subnet_id         = "${ openstack_networking_subnet_v2.subnet.id }"
}
