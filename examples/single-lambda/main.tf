provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "locust"

  cidr = "10.0.0.0/16"

  azs             = ["us-east-1c", "us-east-1d"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    Name = "locust-public"
  }
  private_subnet_tags = {
    Name = "locust-private"
  }

  tags = {
    Owner       = "user"
    Environment = "dev"
  }

  vpc_tags = {
    Name = "locust-vpc"
  }
}

module "locust" {
  source             = "./locust-infra"
  private_subnet_ids = module.vpc.private_subnets
  public_subnet_ids  = module.vpc.public_subnets
  vpc_id             = module.vpc.vpc_id
}

resource "aws_lambda_function" "locust_job" {
  function_name    = "locust-example-job"
  filename         = var.package
  source_code_hash = filebase64sha256(var.package)

  handler = "handler.start"
  runtime = "nodejs10.x"
  timeout = 15

  role = "${module.locust.iam_role_arn}"

  vpc_config {
    subnet_ids         = concat(module.vpc.public_subnets, module.vpc.private_subnets)
    security_group_ids = ["${module.locust.security_group_id}"]
  }

  environment {
    variables = {
      CHROME_HOST = "${module.locust.chrome_hostname}"
      REDIS_HOST  = "${module.locust.redis_hostname}"
    }
  }

}
