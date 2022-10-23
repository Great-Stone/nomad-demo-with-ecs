variable "default_tags" {
  default = {}
}

variable "prefix" {
  default = "amore"
}

variable "vpc_cidr_block" {
  description = "The CIDR block range to use when creating the VPC."
  type        = string
  default     = "10.0.10.0/24"
}

variable "region" {
  description = "AWS region for ECS cluster. Update Nomad config if not using the default."
  type        = string
  default     = "ap-northeast-2"
}

variable "client_count" {
  default = 2
}

variable "server_count" {
  default = 3
}

# already env setting
variable "my_ssh" {
  default = "my_ssh_key"
}

variable "my_vpc"{
  default = "vpc_id"
}

variable "my_subnet"{
  default = "subnet_id"
}

variable "availability_zones" {
  default = "ap-northeast-2a"
}

