terraform {
  cloud {
    organization = "my-mega"
    hostname = "app.terraform.io"

    workspaces {
      name = "amore-nomad-ecs"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
    nomad = {
      source = "hashicorp/nomad"
      version = ">= 1.4.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.default_tags
  }
}

resource "aws_ecs_cluster" "nomad_remote_driver_demo" {
  name = var.ecs_cluster_name
}

# ecs FARGATE 작업 정의
resource "aws_ecs_task_definition" "nomad_remote_driver_demo" {
  family                   = aws_ecs_cluster.nomad_remote_driver_demo.name
  container_definitions    = file(var.ecs_task_definition_file)
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
}

# resource "aws_ecs_task_definition" "nomad_remote_driver_demo_ec2" {
#   family                   = data.terraform_remote_state.net.outputs.ecs_cluster_name
#   container_definitions    = file(var.ecs_task_definition_file)
#   requires_compatibilities  = ["EC2"]
#   network_mode             = "bridge"
#   placement_constraints {
#     type       = "memberOf"
#     expression = "attribute:ecs.availability-zone in [ap-northeast-2a, ap-northeast-2b]"
#   }
#   # cpu                      = 1024
#   # memory                   = 2048
# }

provider "nomad" {
  address = var.nomad_server_dns
  region  = "global"
}

# nomad ecs용 namespace 생성
resource "nomad_namespace" "ecs" {
  name        = "ecs"
  description = "ECS Demo"
}

# ecs sample job 생성
data "template_file" "nomad_ecs_job" {
  template = file("${path.module}/job_file/demo-ecs.tpl")
  vars = {
    namespace         = nomad_namespace.ecs.name
    task_definition   = split("/", aws_ecs_task_definition.nomad_remote_driver_demo.arn)[1]
    security_group_id = var.my_sgi
    subnet_id         = var.my_subnet
  }
}

# ecs install job 생성
data "template_file" "nomad_install_ecs_job" {
  template = file("${path.module}/job_file/ecs-install.tpl")
  vars = {
    cluster_name = var.ecs_cluster_name
    region_name = var.region
  }
}

/*
#auto job deploy ecs sample
resource "nomad_job" "nomad_ecs_job" {
  jobspec = <<EOT
${data.template_file.nomad_ecs_job.rendered}
  EOT
}
*/

#auto job deploy ecs install
resource "nomad_job" "nomad_ecs_install_job" {
  jobspec = <<EOT
${data.template_file.nomad_install_ecs_job.rendered}
  EOT
}
