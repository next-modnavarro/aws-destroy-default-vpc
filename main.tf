provider "aws" {
  region  = var.region
  profile = "test"
}

## reserved for future compatibility with newer terraform versions
## we'll use this resource to loop over certain regions based on filters.
## destroy-vpc-module will iterate over each region looking for default resources
# data "aws_regions" "current" {
#   filter {
#     name   = "region-name"
#     values = ["eu-central-1"]
#   }
# }

data "aws_availability_zones" "available" {
  state = "available"
}

module "destroy-default-vpc" {
  source = "git@github.com:next-modnavarro/terraform-aws-destroy-default-vpc.git"
  azs    = data.aws_availability_zones.available.names
  ## reserved for future compatibility with newer terraform versions.
  ## Loops are not yet supported in aws.provider, see:  https://github.com/hashicorp/terraform/issues/26118
  # for_each  = toset(data.aws_regions.current.names) #this loop should be done on aws provider
  # region = each.region
  region = var.region
}

## Deprecated
# data "aws_vpc" "default" {
#   id         = "${module.destroy-default-vpc.vpc.id}"
#   cidr_block = "${module.destroy-default-vpc.vpc.cidr_block}"
#   depends_on = [module.destroy-default-vpc.vpc]
#   ## reserved for future compatibility with newer terraform versions
#   # for_each   = tomap(module.destroy-default-vpc)
#   # id         = each.value.vpc.id
# }

resource "time_sleep" "wait_30_seconds" {
  create_duration = "30s"
}

# This will create a provider section under each regional folder and trigger terraform init inside of it.
resource "local_file" "default-provider" {
  filename        = "${var.region}/provider.tf"
  file_permission = "0660"

  content = templatefile("./provider.tpl", {
    region = var.region
  })

  provisioner "local-exec" {
    working_dir = "${path.module}/${var.region}"
    command     = "terraform init"
  }
}

# Like previous resource, this will create a tf resource and trigger terraform import of default vpc
resource "local_file" "default-vpc" {
  filename        = "${var.region}/vpc.tf"
  file_permission = "0660"

  content = templatefile("./vpc.tpl", {
    cidr_block = "${module.destroy-default-vpc.vpc.cidr_block}"
  })

  provisioner "local-exec" {
    working_dir = "${path.module}/${var.region}"
    command     = "terraform import -lock-timeout=60s aws_vpc.default ${module.destroy-default-vpc.vpc.id}"
  }

  depends_on = [local_file.default-provider]
}

# We need to create a resource where to import default internet gateway, otherwise vpc deletion won't be achieved
resource "local_file" "default-ig" {
  filename        = "${var.region}/ig.tf"
  file_permission = "0660"

  content = templatefile("./ig.tpl", {
    vpc_id = "${module.destroy-default-vpc.vpc.id}"
  })

  provisioner "local-exec" {
    working_dir = "${path.module}/${var.region}"
    command     = "terraform import -lock-timeout=60s aws_internet_gateway.default-ig ${module.destroy-default-vpc.internet_gateway.id}"
  }

  depends_on = [local_file.default-vpc]
}

# We need to create a resource where to import every subnet associated, otherwise vpc deletion won't be achieved
resource "local_file" "default-az" {
  count           = length(module.destroy-default-vpc.subnets)
  filename        = "${var.region}/${module.destroy-default-vpc.subnets[count.index].availability_zone}.tf"
  file_permission = "0660"

  content = templatefile("./subnet.tpl", {
    name       = "${module.destroy-default-vpc.subnets[count.index].availability_zone}"
    vpc_id     = "${module.destroy-default-vpc.subnets[count.index].vpc_id}"
    cidr_block = "${module.destroy-default-vpc.subnets[count.index].cidr_block}"
  })
  provisioner "local-exec" {
    working_dir = "${path.module}/${var.region}"
    command     = "terraform import -parallelism=1 -lock-timeout=90s aws_subnet.${module.destroy-default-vpc.subnets[count.index].availability_zone} ${module.destroy-default-vpc.subnets[count.index].id}"
  }

  depends_on = [time_sleep.wait_30_seconds, local_file.default-ig]

}
