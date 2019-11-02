variable "private_subnet_ids" {
  description = "List of IDs of private subnets in the VPC"
}

variable "public_subnet_ids" {
  description = "List of IDs of public subnets in the VPC"
}

variable "vpc_id" {
  description = "ID of the VPC to create infra in"
}

variable "chrome_port" {
  description = "Port exposed by Chrome for websocket connections from Locust"
  default     = "3000"
}
