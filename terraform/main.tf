# ==================================================================
# 🔹 Terraform Provider Configuration
# ==================================================================
terraform {
  required_version = ">= 1.4.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }

  backend "s3" {
    bucket         = "terraformbackendaccess"
    key            = "terraformbackendaccess.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock-table" # Prevents concurrent modifications
  }
}

# ==================================================================
# 🔹 AWS Provider Configuration
# ==================================================================
provider "aws" {
  region = "us-east-1"
}

# ==================================================================
# 🔹 VPC Configuration
# ==================================================================
resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "MyVPC"
  }
}

# ==================================================================
# 🔹 Public Subnet Configuration
# ==================================================================
resource "aws_subnet" "my_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "MySubnet"
  }
}

# ==================================================================
# 🔹 Security Group Configuration
# ==================================================================
resource "aws_security_group" "my_security_group" {
  vpc_id = aws_vpc.my_vpc.id

  # Allow inbound HTTP traffic
  ingress {
    description = "Allow HTTP inbound traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MySecurityGroup"
  }
}

# ==================================================================
# 🔹 Elastic Container Registry (ECR)
# ==================================================================
resource "aws_ecr_repository" "my_repository" {
  name = "my-repository"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "MyECRRepository"
  }
}

# ==================================================================
# 🔹 ECS Cluster
# ==================================================================
resource "aws_ecs_cluster" "my_cluster" {
  name = "my-cluster"

  tags = {
    Name = "MyECSCluster"
  }
}

# ==================================================================
# 🔹 ECS Task Definition
# ==================================================================
resource "aws_ecs_task_definition" "my_task_definition" {
  family                   = "my-task-definition"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  memory                   = "512"
  cpu                      = "256"

  container_definitions = jsonencode([
    {
      name  = "my-container"
      image = "${aws_ecr_repository.my_repository.repository_url}:latest"
      memoryReservation = 256
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/my-task"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "MyECSTask"
  }
}

# ==================================================================
# 🔹 ECS Service
# ==================================================================
resource "aws_ecs_service" "my_service" {
  name            = "my-service"
  cluster        = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.my_task_definition.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    subnets          = [aws_subnet.my_subnet.id]
    security_groups  = [aws_security_group.my_security_group.id]
    assign_public_ip = true
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  tags = {
    Name = "MyECSService"
  }
}
