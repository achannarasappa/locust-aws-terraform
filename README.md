# locust-aws-terraform

Terraform module defining the base resources needed to run Locust on AWS

## Usage

```hcl
module "locust" {
  source             = "github.com/achannarasappa/locust-aws-terraform"
  private_subnet_ids = ["subnet-015dff3947245c2e3"]
  public_subnet_ids  = ["subnet-0766addedaf8eada0"]
  vpc_id             = "vpc-0342797f487e2b072"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| vpc_id | ID of the VPC to create resources in | string |  | yes |
| private_subnet_ids | List of IDs of private subnets in the VPC | list(string) |  | yes |
| public_subnet_ids | List of IDs of public subnets in the VPC | list(string) |  | yes |
| chrome_port | Port exposed by Chrome for websocket connections from Locust | string | `"3000"` | yes |

## Outputs

| Name | Description |
|------|-------------|
| redis_hostname | Hostname for the Redis instance containing the Locust queue |
| chrome_hostname | Hostname for the Chrome instance used to execute HTTP requests  |
| security_group_id | Security group for resources related to Locust |
| iam_role_arn | AWS ARN with permissions for an AWS Lambda to connect to Chrome and Redis and run a Locust in a AWS Lambda |

## Examples

Refer to examples directory for how to use this module