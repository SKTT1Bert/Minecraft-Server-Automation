terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

# Data source for Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create VPC
resource "aws_vpc" "minecraft_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "minecraft_igw" {
  vpc_id = aws_vpc.minecraft_vpc.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
  }
}

# Create public subnet
resource "aws_subnet" "minecraft_public_subnet" {
  vpc_id                  = aws_vpc.minecraft_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet"
    Environment = var.environment
  }
}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Create route table for public subnet
resource "aws_route_table" "minecraft_public_rt" {
  vpc_id = aws_vpc.minecraft_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.minecraft_igw.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
  }
}

# Associate route table with public subnet
resource "aws_route_table_association" "minecraft_public_rta" {
  subnet_id      = aws_subnet.minecraft_public_subnet.id
  route_table_id = aws_route_table.minecraft_public_rt.id
}

# Create security group
resource "aws_security_group" "minecraft_sg" {
  name_prefix = "${var.project_name}-sg"
  vpc_id      = aws_vpc.minecraft_vpc.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # Minecraft server port
  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Minecraft server"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-sg"
    Environment = var.environment
  }
}

# Create key pair
resource "aws_key_pair" "minecraft_key" {
  key_name   = "${var.project_name}-key"
  public_key = file(var.public_key_path)

  tags = {
    Name        = "${var.project_name}-key"
    Environment = var.environment
  }
}

# Create EC2 instance
resource "aws_instance" "minecraft_server" {
  ami                     = data.aws_ami.amazon_linux.id
  instance_type           = var.instance_type
  key_name                = aws_key_pair.minecraft_key.key_name
  vpc_security_group_ids  = [aws_security_group.minecraft_sg.id]
  subnet_id               = aws_subnet.minecraft_public_subnet.id
  
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
  }

  # Wait for instance to be ready, then run Ansible
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for instance to be ready..."
      sleep 60
      
      # Create temporary inventory file
      echo "[minecraft_servers]" > inventory.tmp
      echo "${self.public_ip} ansible_user=ec2-user ansible_ssh_private_key_file=${var.private_key_path}" >> inventory.tmp
      
      # Run Ansible playbook
      ansible-playbook -i inventory.tmp playbook.yml
      
      # Clean up temporary file
      rm inventory.tmp
    EOT
  }

  tags = {
    Name        = "${var.project_name}-server"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.minecraft_igw]
} 