This terraform will create a folder named after the selected region and will import into it all default vpc and associated resources to make it easier to delete (terraform destroy)
**WARNING:** The management of default VPC resources in AWS is meant to close security holes and follow best
practices. If you have an architecture that relies on default VPC resources **DO NOT** use this module until those
resources have been moved to non-default resources.


## Usage
```
terraform plan
terraform apply
cd <region>
terraform destroy
```

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 0.13.0 |
| aws | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| region | AWS Region | `string` | `"eu-west-1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc | The Default VPC |
| subnets | The Default Subnets |
| network\_acl | The Default Network ACL |
| internet\_gateway | The Default internet_gateway |
