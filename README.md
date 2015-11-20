# Terraform

Infrastructure automation using terraform on OpenStack.
This automation brings a few features: package autoupgrade, hostname fix, manage host resolvers and domain, managed DNS on separate instance (SkyDNS)

Hosts are provisioned with templated cloud-config, where all changes are applying on every instance boot, also instances are automatically self-geristering their hostname and IP address in etcd, which gives SkyDNS serve this names as DNS records.

## More about SkyDNS
[SkyDNS](https://github.com/skynetservices/skydns) is dynamic DNS server with etcd backend
Nameserver instance contains: etcd server, docker daemon, skydns container, etcd browser (port 8000). All components are installed via cloud-config.

## Usage

Complete the variables in terraform.tfvars, please note that DNS runs on CoreOS. You can download image for OpenStack [on Coreos website](https://coreos.com/os/docs/latest/booting-on-openstack.html). Read the notes how to upload image into Glance image service.

Example:

```shell
glance image-create --name CoreOS \
  --container-format bare \
  --disk-format qcow2 \
  --file coreos_production_openstack_image.img \
  --progress
```

Then run:

```shell
terraform get
terraform plan -module-depth=1
```

If you are happy with what `terraform plan` is suggesting, run;

```shell
terraform apply
```

To show all resources created run:
```shell
terraform show -module-depth=1
```
