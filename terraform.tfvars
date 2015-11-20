# Terraform Variables Definitions

auth_url = ""
tenant_id = ""
tenant_name = ""
master_count = 1
node_count = 2
public_key = "~/.ssh/id_rsa.pub"
keypair_name = ""
cluster_name = ""
master_flavor = ""
node_flavor = ""
image_name = ""
keypair_name = "${ module.openstack-keypair.keypair_name }"
security_groups = "${ module.openstack-secgroup.cluster_name }"
floating_pool = ""
external_net_id = ""
subnet_cidr = "10.10.5.0/24"
docker_master_volume = 10
docker_node_volume = 20
dns_domain = ""
dns_nameservers = "10.10.5.253"
dns_flavor = ""
dns_image_name = "CoreOS"
