variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "minecraft-server"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
  
  validation {
    condition     = contains(["t2.micro", "t3.small", "t3.medium"], var.instance_type)
    error_message = "Instance type must be one of: t2.micro, t3.small, t3.medium."
  }
}

variable "public_key_path" {
  description = "Path to the public key file"
  type        = string
  default     = "~/.ssh/minecraft-key.pub"
}

variable "private_key_path" {
  description = "Path to the private key file"
  type        = string
  default     = "~/.ssh/minecraft-key.pem"
}

variable "minecraft_version" {
  description = "Minecraft server version to install"
  type        = string
  default     = "1.20.4"
}

variable "minecraft_memory" {
  description = "Memory allocation for Minecraft server (in MB)"
  type        = number
  default     = 1024
}

variable "minecraft_max_players" {
  description = "Maximum number of players"
  type        = number
  default     = 20
} 