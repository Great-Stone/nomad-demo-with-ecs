variable "default_tags" {
  default = {}
}

variable "prefix" {
  default = "amore"
}

variable "vpc_cidr_block" {
  description = "The CIDR block range to use when creating the VPC."
  type        = string
  default     = "10.0.0.0/24"
}

variable "region" {
  description = "AWS region for ECS cluster. Update Nomad config if not using the default."
  type        = string
  default     = "ap-northeast-2"
}

variable "client_count" {
  default = 2
}

variable "ecs_cluster_name" {
  default = "nomad-ecs-remote-demo"
}

# variable "license_file" {
#   type        = string
#   default     = file("./files/nomad.hclic")
# }