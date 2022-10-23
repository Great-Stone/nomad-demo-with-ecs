variable "default_tags" {
  type    = map(any)
  default = {}
}

variable "ecs_task_definition_file" {
  description = "The file that contains the ECS task definition, used as a deployment/update trick."
  type        = string
  default     = "./files/base-demo.json"
}

variable "region" {
  description = "AWS region for ECS cluster. Update Nomad config if not using the default."
  type        = string
  default     = "ap-northeast-2"
}

variable "ecs_cluster_name" {
  default     = "ecs_cluster"
}

variable "nomad_server_dns" {
  default     = "nomad_server_dns"
}

variable "my_sgi" {
  default = "my_sgi"
}

variable "my_subnet" {
  default = "my_subnet"
}
