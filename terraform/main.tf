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
  region      = "us-east-1"
  max_retries = 1

}

resource "aws_key_pair" "access_key" {
  key_name   = "deploy-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCZN1DH2v5vfMljWidtzG8Nt5pDiO5PwCKrDMGUAv3Jh/WRmoEnQdrLxRKC8jQ+g4EwPs37ECThDptMV9HfLE7sy7JDY86pNt1ttjwpsUFBjreP6GjM7RZbkAoP31W4a3hc3LYb6lTTiy33/Bje7sN1CKXBw3lq20/S0FguG8XSy+/PXz1HFYiglgg6KzVAfI8B+v0E9wokwIk7KDa54Bs7HJuCjACCjF9MEnGmOAjqzE+Kr1ZQT3ruPpDInUWwOwLyvrWLm9R5pS8RZBBWRsD2upjFYGQ0x5eUebWTVTm6UMsWrFkNOaaWT1Tbbfp861JJKKydN8U4NtTqAUaVSIYp rsa-key-20211017"
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
  availability_zone = "us-east-1e"

  tags = {
    Name = "app_private_subnet"
  }
}
resource "aws_subnet" "app_public_subnet" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "192.168.10.0/24"
  availability_zone = "us-east-1e"

  tags = {
    Name = "app_public_subnet"
  }
}


# Network Interfaces
resource "aws_network_interface" "bridge-nic" {
  subnet_id = aws_subnet.app_private_subnet.id

  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_network_interface" "node1-nic" {
  subnet_id = aws_subnet.app_public_subnet.id

  tags = {
    Name = "primary_network_interface"
  }
}

# EC2 Instances
resource "aws_instance" "bridge" {
  ami                  = "ami-02e136e904f3da870" # us-east-1 am2
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
  ami           = "ami-02e136e904f3da870" # us-east-1 am2
  instance_type = "t2.micro"
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

# route tables
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
