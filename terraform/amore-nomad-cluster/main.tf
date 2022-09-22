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


resource "aws_vpc" "nomad_demo" {
  cidr_block = var.vpc_cidr_block
}

resource "aws_subnet" "nomad_demo" {
  cidr_block = var.vpc_cidr_block
  vpc_id     = aws_vpc.nomad_demo.id
}

resource "aws_internet_gateway" "nomad_demo" {
  vpc_id = aws_vpc.nomad_demo.id
}

resource "aws_route_table" "nomad_demo" {
  vpc_id = aws_vpc.nomad_demo.id
}

resource "aws_route" "nomad_demo" {
  route_table_id         = aws_route_table.nomad_demo.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.nomad_demo.id
}

resource "aws_route_table_association" "nomad_demo" {
  subnet_id      = aws_subnet.nomad_demo.id
  route_table_id = aws_route_table.nomad_demo.id
}

// data "http" "myip" {
//   url = "https://api.myip.com"

//   request_headers = {
//     Accept = "application/json"
//   }
// }

resource "aws_security_group" "nomad_ecs" {
  vpc_id = aws_vpc.nomad_demo.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    // cidr_blocks = ["${jsondecode(data.http.myip.response_body).ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "nomad_server" {
  vpc_id = aws_vpc.nomad_demo.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    // cidr_blocks = ["${jsondecode(data.http.myip.response_body).ip}/32"]
  }

  ingress {
    from_port   = 4646
    to_port     = 4646
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    // cidr_blocks = ["${jsondecode(data.http.myip.response_body).ip}/32"]
  }

  ingress {
    from_port   = 4647
    to_port     = 4647
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.nomad_demo.cidr_block]
    // cidr_blocks = ["${jsondecode(data.http.myip.response_body).ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "nomad_client" {
  vpc_id = aws_vpc.nomad_demo.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    // cidr_blocks = ["${jsondecode(data.http.myip.response_body).ip}/32"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    // cidr_blocks = ["${jsondecode(data.http.myip.response_body).ip}/32"]
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    // cidr_blocks = ["${jsondecode(data.http.myip.response_body).ip}/32"]
  }

  ingress {
    from_port   = 28080
    to_port     = 28080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    // cidr_blocks = ["${jsondecode(data.http.myip.response_body).ip}/32"]
  }

  ingress {
    from_port   = 20000
    to_port     = 32000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    // cidr_blocks = ["${jsondecode(data.http.myip.response_body).ip}/32"]
  }

  
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#################

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "example" {
  key_name   = "${var.prefix}-key-pair"
  public_key = tls_private_key.example.public_key_openssh
}

data "template_file" "server" {
  template = file("./template/install_server.tpl")
  vars = {
    license         = file("./files/nomad.hclic")
  }
}

resource "aws_eip" "server" {
  vpc      = true
  instance = aws_instance.server.id
}

data "aws_ami" "example" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "server" {
  subnet_id     = aws_subnet.nomad_demo.id
  ami           = data.aws_ami.example.image_id
  instance_type = "m5.large"
  key_name      = aws_key_pair.example.key_name
  vpc_security_group_ids = [
    aws_security_group.nomad_server.id
  ]
  user_data = data.template_file.server.rendered

  tags = {
    type = "${var.prefix}-nomad-server"
  }

  lifecycle {
    ignore_changes = [
      user_data,
    ]
  }
}

// data "external" "env" {
//   program = ["${path.module}/env.sh"]
// }

data "template_file" "client" {
  template = file("./template/install_client.tpl")

  vars = {
    tag_value = "${var.prefix}-nomad-server"
    region = var.region
    clustername = var.ecs_cluster_name
    // aws_access_key_id = external.env.result["id"]
    // aws_secret_access_key = external.env.result["secret"]
    // aws_session_token = external.env.result["token"]
  }
}

resource "aws_eip" "client" {
  count    = var.client_count
  vpc      = true
  instance = aws_instance.client[count.index].id
}

resource "aws_instance" "client" {
  count         = var.client_count
  subnet_id     = aws_subnet.nomad_demo.id
  ami           = data.aws_ami.example.image_id
  instance_type = "m5.xlarge"
  key_name      = aws_key_pair.example.key_name
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

############
# Policy

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