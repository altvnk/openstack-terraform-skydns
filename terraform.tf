variable auth_url { }
variable tenant_id { }
variable tenant_name { }
variable public_key { }
variable keypair_name { }
variable cluster_name { }
variable master_flavor { }
variable node_flavor { }
variable image_name { }
variable master_count { }
variable node_count { }
variable floating_pool { }
variable external_net_id { }
variable subnet_cidr { }
variable docker_master_volume { }
variable docker_node_volume { }
variable dns_domain { }
variable dns_nameservers { }
variable dns_flavor { }
variable dns_image_name { }

provider "openstack" {
  auth_url              = "${ var.auth_url }"
  tenant_id             = "${ var.tenant_id }"
  tenant_name           = "${ var.tenant_name }"
}

module "openstack-keypair" {
  source                = "./keypair"
  public_key            = "${ var.public_key }"
  keypair_name          = "${ var.keypair_name }"
}

module "openstack-secgroup" {
  source                = "./secgroup"
  cluster_name          = "${ var.cluster_name }"
}

module "openstack-hosts" {
  source                = "./hosts"
  master_flavor         = "${ var.master_flavor }"
  node_flavor           = "${ var.node_flavor }"
  image_name            = "${ var.image_name }"
  keypair_name          = "${ module.openstack-keypair.keypair_name }"
  security_groups       = "${ module.openstack-secgroup.cluster_name }"
  master_count          = "${ var.master_count }"
  node_count            = "${ var.node_count }"
  floating_pool         = "${ var.floating_pool }"
  external_net_id       = "${ var.external_net_id }"
  subnet_cidr           = "${ var.subnet_cidr }"
  docker_master_volume  = "${ var.docker_master_volume }"
  docker_node_volume    = "${ var.docker_node_volume }"
  dns_domain            = "${ var.dns_domain }"
  dns_nameservers       = "${ var.dns_nameservers }"
  dns_flavor            = "${ var.dns_flavor }"
  dns_image_name        = "${ var.dns_image_name }"
}
