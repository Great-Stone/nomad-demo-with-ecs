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

data "terraform_remote_state" "net" {
  backend = "remote"

  config = {
    organization = "my-mega"
    workspaces = {
      name = "amore-nomad-cluster"
    }
  }
}

resource "aws_ecs_cluster" "nomad_remote_driver_demo" {
  name = data.terraform_remote_state.net.outputs.ecs_cluster_name
}

resource "aws_ecs_task_definition" "nomad_remote_driver_demo" {
  family                   = aws_ecs_cluster.nomad_remote_driver_demo.name
  container_definitions    = file(var.ecs_task_definition_file)
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
}

provider "nomad" {
  address = data.terraform_remote_state.net.outputs.nomad_server_dns
  region  = "global"
}

resource "nomad_namespace" "ecs" {
  name        = "ecs"
  description = "ECS Demo"
}

data "template_file" "nomad_ecs_job" {
  template = file("${path.module}/job_file/demo-ecs.tpl")
  vars = {
    namespace         = nomad_namespace.ecs.name
    task_definition   = split("/", aws_ecs_task_definition.nomad_remote_driver_demo.arn)[1]
    security_group_id = data.terraform_remote_state.net.outputs.demo_security_group_id
    subnet_id         = data.terraform_remote_state.net.outputs.demo_subnet_id
  }
}

#auto job deploy
resource "nomad_job" "nomad_ecs_job" {
  jobspec = <<EOT
${data.template_file.nomad_ecs_job.rendered}
  EOT
}

#prometheus job deploy
resource "nomad_job" "nomad_prom_job" {
  jobspec = file("./job_file/prometheus.tpl")
}

#autoscaler job deploy
resource "nomad_job" "nomad_das_job" {
  jobspec = file("./job_file/autoscaler.tpl")
}

#das sample job deploy
resource "nomad_job" "nomad_sample_job" {
  jobspec = file("./job_file/example.tpl")
}

#sample load test job deploy
resource "nomad_job" "nomad_load_test_job" {
  jobspec = file("./job_file/load-test.tpl")
}
