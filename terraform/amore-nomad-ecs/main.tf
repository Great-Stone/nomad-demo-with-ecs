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

resource "aws_security_group" "nomad_ecs" {
  vpc_id = var.my_vpc

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "example_ecs_cluster" {
  source       = "github.com/jetbrains-infra/terraform-aws-ecs-cluster?ref=v0.5.3" // see https://github.com/jetbrains-infra/terraform-aws-ecs-cluster/releases
  cluster_name = var.ecs_cluster_name
  arm64           = true
  instance_types = {
    "t4g.large" = 2
  }

  // subnets where the ECS nodes are hosted
  subnets_ids = [
    "subnet-00d553b072fac7adc",
    "subnet-0ead0e8ad679fc811"
  ]

  trusted_cidr_blocks = [
    "0.0.0.0/0"
  ]

  security_group_ids = [ 
    aws_security_group.nomad_ecs.id
  ]

}

# ecs FARGATE 작업 정의
resource "aws_ecs_task_definition" "nomad_remote_driver_demo" {
  family                   = module.example_ecs_cluster.name
  container_definitions    = file(var.ecs_task_definition_file)
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = module.example_ecs_cluster.ecs_default_task_role_arn
  task_role_arn            = module.example_ecs_cluster.ecs_default_task_role_arn
  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [ap-northeast-2a, ap-northeast-2b]"
  }
}

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
    security_group_id = aws_security_group.nomad_ecs.id
    subnet_id1         = "subnet-00d553b072fac7adc"
    subnet_id2         = "subnet-0ead0e8ad679fc811"
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

# /*
# #auto job deploy ecs sample
# resource "nomad_job" "nomad_ecs_job" {
#   jobspec = <<EOT
# ${data.template_file.nomad_ecs_job.rendered}
#   EOT
# }
# */

# #auto job deploy ecs install
resource "nomad_job" "nomad_ecs_install_job" {
  jobspec = <<EOT
${data.template_file.nomad_install_ecs_job.rendered}
  EOT
}

#auto job deploy ecs sample
# resource "nomad_job" "nomad_ecs_job" {
#   jobspec = <<EOT
# job "nomad-ecs-demo" {
#   datacenters = ["dc1"]
#   namespace = "${nomad_namespace.ecs.name}"

#   group "ecs-remote-task-demo" {
#     count = 1

#     scaling {
#       enabled = true
#       min = 0
#       max = 5
#     }

#     restart {
#       attempts = 0
#       mode     = "fail"
#     }

#     reschedule {
#       delay = "5s"
#     }

#     task "http-server" {
#       driver       = "ecs"
#       kill_timeout = "1m" // increased from default to accomodate ECS.

#       config {
#         task {
#           launch_type     = "FARGATE"
#           task_definition = "${split("/", aws_ecs_task_definition.nomad_remote_driver_demo.arn)[1]}"
#           network_configuration {
#             aws_vpc_configuration {
#               assign_public_ip = "ENABLED"
#               security_groups  = ["${var.my_sgi}"]
#               subnets          = ["${var.my_subnet}"]
#             }
#           }
#         }
#       }

#       resources {
#         cpu    = 20
#         memory = 10
#       }
#     }
#   }
# }
#   EOT
# }

# resource "nomad_job" "nomad_ecs_install_job" {
#   jobspec = <<EOT
# job "install_ecs_plugin" {
#   datacenters = ["dc1"]
  
#   type        = "sysbatch"
  
#   group "install" {
#     task "ecs-plugin" {
#       driver = "raw_exec"
#       template {
#         data = <<EOF
# #!/bin/bash
# sudo cat <<EOCONFIG >> /etc/nomad.d/nomad.hcl
# plugin "nomad-driver-ecs" {
#   config {
#     enabled = true
#     cluster = "${var.ecs_cluster_name}"
#     region  = "${var.region}"
#   }
# }
# EOCONFIG
# cat /etc/nomad.d/nomad.hcl
# sudo systemctl restart nomad
# sudo systemctl status nomad
# EOF
#         destination = "ecs_install.sh"
#       }
#       config {
#         command = "ecs_install.sh"
#       }
#       resources {
#         cpu    = 100
#         memory = 64
#       }
#     }
#   }
# }
#   EOT
# }