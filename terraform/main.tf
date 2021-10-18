terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile     = "default"
  region      = var.aws_region
  max_retries = 1

}

resource "aws_key_pair" "access_key" {
  key_name   = "deploy_key"
  public_key = var.deploy_key_public_key
}

resource "aws_vpc" "app_vpc" {
  cidr_block = "192.168.0.0/16"

  tags = {
    Name = "app_lab"
  }
}

# Subnets
resource "aws_subnet" "app_private_subnet" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "192.168.20.0/24"
  availability_zone = "${var.aws_region}e"

  tags = {
    Name = "app_private_subnet"
  }
}
resource "aws_subnet" "app_public_subnet" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "192.168.10.0/24"
  availability_zone = "${var.aws_region}e"

  tags = {
    Name = "app_public_subnet"
  }
}


# Network Interfaces
resource "aws_network_interface" "bridge-nic" {
  subnet_id       = aws_subnet.app_private_subnet.id
  security_groups = [aws_security_group.all_internal_allow.id]
  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_network_interface" "node1-nic" {
  subnet_id       = aws_subnet.app_public_subnet.id
  security_groups = [aws_security_group.all_internal_allow.id, aws_security_group.inbound_all_http_allow.id]
  tags = {
    Name = "primary_network_interface"
  }
}

# EC2 Instances
resource "aws_instance" "bridge" {
  ami                  = var.linux_ami
  instance_type        = "t2.micro"
  iam_instance_profile = "AmazonSSMRoleForInstancesQuickSetup"

  network_interface {
    network_interface_id = aws_network_interface.bridge-nic.id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "unlimited"
  }
  user_data = <<EOF
  #!/bin/bash
  echo "set hostname"
  sudo hostnamectl set-hostname bridge
  echo "Install Ansible"
  sudo yum update -y
  sudo amazon-linux-extras install ansible2 -y
  EOF
  tags = {
    Name = "bridge"
  }
}

resource "aws_instance" "node1" {
  ami           = var.linux_ami
  instance_type = var.node_instance_type
  key_name      = aws_key_pair.access_key.key_name
  network_interface {
    network_interface_id = aws_network_interface.node1-nic.id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "unlimited"
  }
  user_data = <<EOF
  #!/bin/bash
  echo "set hostname"
  sudo hostnamectl set-hostname node1
  EOF
  tags = {
    "Name" = "node1"
  }
}


# Public IPs
resource "aws_eip" "node1_eip" {
  instance = aws_instance.node1.id

  depends_on = [aws_internet_gateway.app_gw]
  vpc        = true
}

resource "aws_eip" "nat_eip" {
  vpc = true
}

# Gateways (IGW and NAT)
resource "aws_internet_gateway" "app_gw" {
  vpc_id = aws_vpc.app_vpc.id
}
resource "aws_nat_gateway" "private_subnet_nat" {
  connectivity_type = "public"
  allocation_id     = aws_eip.nat_eip.id
  subnet_id         = aws_subnet.app_public_subnet.id

  tags = {
    Name = "private_subnet_nat"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.app_gw]
}

# Route tables
resource "aws_route_table" "default_igw_route_table" {
  vpc_id = aws_vpc.app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_gw.id
  }

  tags = {
    Name = "Default Route to Internet Gateway"
  }
}

resource "aws_route_table" "default_nat_route_table" {
  vpc_id = aws_vpc.app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.private_subnet_nat.id
  }

  tags = {
    Name = "Default Route to Nat Gateway"
  }
}

# route table associations
resource "aws_route_table_association" "private_nat_association" {
  subnet_id      = aws_subnet.app_private_subnet.id
  route_table_id = aws_route_table.default_nat_route_table.id
}

resource "aws_route_table_association" "public_igw_association" {
  subnet_id      = aws_subnet.app_public_subnet.id
  route_table_id = aws_route_table.default_igw_route_table.id
}

# Security Group
resource "aws_security_group" "inbound_all_http_allow" {
  name = "inbound_all_http_allow"

  ingress {
    description = "Allow all HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = aws_vpc.app_vpc.id

  tags = {
    Name = "inbound_all_http_allow"
  }
}

resource "aws_security_group" "all_internal_allow" {
  name = "all_internal_allow"

  ingress {
    description = "Allow all internal traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.app_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = aws_vpc.app_vpc.id

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "all_internal_allow"
  }
}