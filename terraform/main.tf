terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

provider "aws" {
  region = var.region
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

data "http" "myip" {
  url = "https://api.myip.com"

  request_headers = {
    Accept = "application/json"
  }
}

resource "aws_security_group" "nomad_demo" {
  vpc_id = aws_vpc.nomad_demo.id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    // cidr_blocks = ["0.0.0.0/0"]
    cidr_blocks = ["${jsondecode(data.http.myip.response_body).ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
