output "default_vpc_id" {
  ## reserved for future compatibility with newer terraform versions
  # value = { for k, v in module.destroy-default-vpc : k => v.vpc.id }
  value = "${module.destroy-default-vpc.vpc.id}"
}

output "subnets" {
  value = join(",", "${module.destroy-default-vpc.subnets[*].id}")
}

output "network_acl" {
  value = "${module.destroy-default-vpc.network_acl.id}"
}

output "internet_gateway" {
  value = "${module.destroy-default-vpc.internet_gateway.id}"
}
