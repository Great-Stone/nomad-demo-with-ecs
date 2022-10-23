terraform {
  cloud {
    organization = "my-mega"
    hostname     = "app.terraform.io"

    workspaces {
      name = "amore-nomad-cluster"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.default_tags
  }
}

################################
## nomad-cluster network 설정 ##
################################

data "aws_vpc" "nomad_demo"{
  id = var.my_vpc
}

data "aws_subnet" "nomad_demo" {
  id = var.my_subnet
}

resource "aws_internet_gateway" "nomad_demo" {
  vpc_id = data.aws_vpc.nomad_demo.id
}

resource "aws_route_table" "nomad_demo" {
  vpc_id = data.aws_vpc.nomad_demo.id
}

resource "aws_route" "nomad_demo" {
  route_table_id         = aws_route_table.nomad_demo.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.nomad_demo.id
}

resource "aws_route_table_association" "nomad_demo" {
  subnet_id      = data.aws_subnet.nomad_demo.id
  route_table_id = aws_route_table.nomad_demo.id
}

resource "aws_security_group" "nomad_ecs" {
  vpc_id = data.aws_vpc.nomad_demo.id

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

resource "aws_security_group" "nomad_server" {
  vpc_id = data.aws_vpc.nomad_demo.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4646
    to_port     = 4648
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4646
    to_port     = 4648
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 4647
    to_port     = 4648
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 4647
    to_port     = 4648
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "nomad_client" {
  vpc_id = data.aws_vpc.nomad_demo.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 28080
    to_port     = 28080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 20000
    to_port     = 32000
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

##############################
##       nomad server       ##
##############################
data "template_file" "server" {
  template = file("./template/install_server.tpl")
  vars = {
    license = file("./files/nomad.hclic")
    tag_value   = "${var.prefix}-nomad-server"
    region      = var.region
  }
}

resource "aws_eip" "server" {
  vpc      = true
  instance = aws_instance.server[0].id
}

data "aws_ami" "example" {
  most_recent = true
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_instance" "server" {
  count         = var.server_count
  subnet_id     = data.aws_subnet.nomad_demo.id
  ami           = data.aws_ami.example.image_id
  instance_type = "m5.large"
  key_name      = var.my_ssh
  vpc_security_group_ids = [
    aws_security_group.nomad_server.id
  ]
  user_data = data.template_file.server.rendered
  iam_instance_profile = aws_iam_instance_profile.test_profile.name

  tags = {
    type = "${var.prefix}-nomad-server"
  }

  lifecycle {
    ignore_changes = [
      user_data,
    ]
  }
}

##############################
##       nomad client       ##
##############################
data "template_file" "client" {
  template = file("./template/install_client.tpl")

  vars = {
    tag_value   = "${var.prefix}-nomad-server"
    region      = var.region
  }
}

resource "aws_eip" "client" {
  count    = var.client_count
  vpc      = true
  instance = aws_instance.client[count.index].id
}

resource "aws_instance" "client" {
  count         = var.client_count
  subnet_id     = data.aws_subnet.nomad_demo.id
  ami           = data.aws_ami.example.image_id
  instance_type = "m5.large"
  key_name      = var.my_ssh
  vpc_security_group_ids = [
    aws_security_group.nomad_client.id
  ]
  user_data            = data.template_file.client.rendered
  iam_instance_profile = aws_iam_instance_profile.test_profile.name

  lifecycle {
    ignore_changes = [
      user_data,
    ]
  }
}

##############################
##     auto-join policy     ##
##############################
data "aws_iam_policy_document" "instance_role" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance_role" {
  name_prefix        = "${var.prefix}-nomad"
  assume_role_policy = data.aws_iam_policy_document.instance_role.json
}

resource "aws_iam_instance_profile" "test_profile" {
  name = "test_profile"
  role = aws_iam_role.instance_role.name
}

resource "aws_iam_role_policy" "cluster_discovery" {
  name   = "${var.prefix}-nomad-cluster_discovery"
  role   = aws_iam_role.instance_role.id
  policy = data.aws_iam_policy_document.cluster_discovery.json
}

data "aws_iam_policy_document" "cluster_discovery" {
  # allow role with this policy to do the following: list instances, list tags, autoscale
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "autoscaling:CompleteLifecycleAction",
      "ec2:DescribeTags",
      "ecs:ListClusters",
      "ecs:DescribeClusters",
      "ecs:DeregisterContainerInstance",
      "ecs:ListContainerInstances",
      "ecs:RegisterContainerInstance",
      "ecs:SubmitContainerStateChange",
      "ecs:SubmitTaskStateChange",
      "ecs:DescribeContainerInstances",
      "ecs:DescribeTasks",
      "ecs:ListTasks",
      "ecs:UpdateContainerAgent",
      "ecs:StartTask",
      "ecs:StopTask",
      "ecs:RunTask"
    ]
    resources = ["*"]
  }
}