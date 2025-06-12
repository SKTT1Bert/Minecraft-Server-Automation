# ECS-based Minecraft Server Deployment
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

# ECR Repository for Minecraft Docker image
resource "aws_ecr_repository" "minecraft_server" {
  name                 = "${var.project_name}-server"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}-ecr"
    Environment = var.environment
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "minecraft_cluster" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.project_name}-cluster"
    Environment = var.environment
  }
}

# EFS for persistent storage
resource "aws_efs_file_system" "minecraft_data" {
  creation_token   = "${var.project_name}-data"
  performance_mode = "generalPurpose"
  throughput_mode  = "provisioned"
  provisioned_throughput_in_mibps = 10

  tags = {
    Name        = "${var.project_name}-data"
    Environment = var.environment
  }
}

# EFS Mount Target
resource "aws_efs_mount_target" "minecraft_data" {
  file_system_id  = aws_efs_file_system.minecraft_data.id
  subnet_id       = aws_subnet.minecraft_public_subnet.id
  security_groups = [aws_security_group.efs_sg.id]
}

# Security Group for EFS
resource "aws_security_group" "efs_sg" {
  name_prefix = "${var.project_name}-efs-sg"
  vpc_id      = aws_vpc.minecraft_vpc.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-efs-sg"
    Environment = var.environment
  }
}

# Security Group for ECS
resource "aws_security_group" "ecs_sg" {
  name_prefix = "${var.project_name}-ecs-sg"
  vpc_id      = aws_vpc.minecraft_vpc.id

  # Minecraft port
  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP for health checks
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-ecs-sg"
    Environment = var.environment
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "minecraft_server" {
  family                   = "${var.project_name}-server"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  volume {
    name = "minecraft-data"

    efs_volume_configuration {
      file_system_id = aws_efs_file_system.minecraft_data.id
      root_directory = "/"
    }
  }

  container_definitions = jsonencode([
    {
      name  = "minecraft-server"
      image = "${aws_ecr_repository.minecraft_server.repository_url}:latest"
      
      portMappings = [
        {
          containerPort = 25565
          protocol      = "tcp"
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "minecraft-data"
          containerPath = "/data"
        }
      ]

      environment = [
        {
          name  = "MINECRAFT_MEMORY"
          value = "${var.minecraft_memory}M"
        },
        {
          name  = "MINECRAFT_MAX_PLAYERS"
          value = tostring(var.minecraft_max_players)
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.minecraft_logs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "minecraft"
        }
      }

      healthCheck = {
        command = ["CMD-SHELL", "netstat -an | grep :25565 || exit 1"]
        interval = 30
        timeout = 5
        retries = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-task"
    Environment = var.environment
  }
}

# ECS Service
resource "aws_ecs_service" "minecraft_server" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.minecraft_cluster.id
  task_definition = aws_ecs_task_definition.minecraft_server.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.minecraft_public_subnet.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  depends_on = [aws_efs_mount_target.minecraft_data]

  tags = {
    Name        = "${var.project_name}-service"
    Environment = var.environment
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "minecraft_logs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-logs"
    Environment = var.environment
  }
}

# IAM Roles for ECS
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Include VPC configuration from main.tf
# (VPC, subnets, IGW, etc. - same as before) 