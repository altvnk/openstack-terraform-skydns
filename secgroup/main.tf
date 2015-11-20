variable cluster_name { }

resource "openstack_compute_secgroup_v2" "cluster" {
    name = "${ var.cluster_name }"
    description = "Security Group for ${ var.cluster_name }"
    rule {
      from_port = -1
      to_port = -1
      ip_protocol = "icmp"
      self = true
    }
    rule {
      from_port = 22
      to_port = 22
      ip_protocol = "tcp"
      cidr = "0.0.0.0/0"
    }
    rule {
      from_port = 53
      to_port = 53
      ip_protocol = "udp"
      cidr = "0.0.0.0/0"
    }
    rule {
      from_port = 53
      to_port = 53
      ip_protocol = "tcp"
      cidr = "0.0.0.0/0"
    }
}

output "cluster_name" {
  value = "${ openstack_compute_secgroup_v2.cluster.name }"
}
