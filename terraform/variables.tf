variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "container_port" {
  description = "Application container port"
  type        = number
}

variable "desired_count" {
  description = "Number of ECS tasks"
  type        = number
}