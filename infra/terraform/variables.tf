variable "aws_region" {
  description = "AWS region where all resources are deployed."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "aws_region must follow the pattern 'us-east-1'."
  }
}

variable "project" {
  description = "Project name used as prefix for all resource names."
  type        = string
  default     = "platform-ops"

  validation {
    condition     = length(var.project) <= 20
    error_message = "project name must be 20 characters or fewer."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of AZs to deploy subnets into (must match the selected region)."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "eks_cluster_version" {
  description = "Kubernetes version for the EKS control plane."
  type        = string
  default     = "1.30"
}

variable "enable_rds" {
  description = "Set to true to create the optional RDS Postgres instance."
  type        = bool
  default     = false
}

variable "db_password" {
  description = "Master password for the RDS instance. Must be provided via TF_VAR_db_password env var."
  type        = string
  sensitive   = true
  default     = ""
}
