# variables.tf

# ==============================================================================
# AWS Region
# ==============================================================================
variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

# ==============================================================================
# SSH Key
# ==============================================================================
variable "key_name" {
  description = "Name of an existing EC2 KeyPair for SSH access"
  type        = string
  default     = "k8s-key"
}

# ==============================================================================
# VPC Configuration
# ==============================================================================
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# ==============================================================================
# EC2 Instance Types
# ==============================================================================
variable "bastion_instance_type" {
  description = "Instance type for the bastion host"
  type        = string
  default     = "t3.micro"
}

variable "master_instance_type" {
  description = "Instance type for the master nodes"
  type        = string
  default     = "t3.medium"
}

variable "worker_instance_type" {
  description = "Instance type for the worker nodes"
  type        = string
  default     = "t3.medium"
}

# ==============================================================================
# EFS Configuration
# ==============================================================================
variable "efs_performance_mode" {
  description = "EFS performance mode (generalPurpose or maxIO)"
  type        = string
  default     = "generalPurpose"
  
  validation {
    condition     = contains(["generalPurpose", "maxIO"], var.efs_performance_mode)
    error_message = "EFS performance mode must be either 'generalPurpose' or 'maxIO'."
  }
}

variable "efs_throughput_mode" {
  description = "EFS throughput mode (bursting or provisioned)"
  type        = string
  default     = "bursting"
  
  validation {
    condition     = contains(["bursting", "provisioned"], var.efs_throughput_mode)
    error_message = "EFS throughput mode must be either 'bursting' or 'provisioned'."
  }
}

variable "efs_provisioned_throughput" {
  description = "Provisioned throughput in MiB/s (only used if throughput_mode is provisioned)"
  type        = number
  default     = null
}

variable "efs_enable_backup" {
  description = "Enable automatic EFS backups"
  type        = bool
  default     = true
}

variable "efs_transition_to_ia" {
  description = "Number of days after which to transition files to IA storage (AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, AFTER_90_DAYS)"
  type        = string
  default     = "AFTER_30_DAYS"
}

# ==============================================================================
# Tags
# ==============================================================================
variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "k8s-cluster"
}

# ==============================================================================
# ASG Configuration (for future phases)
# ==============================================================================
variable "worker_asg_min_size" {
  description = "Minimum number of worker nodes per AZ"
  type        = number
  default     = 1
}

variable "worker_asg_desired_size" {
  description = "Desired number of worker nodes per AZ"
  type        = number
  default     = 1
}

variable "worker_asg_max_size" {
  description = "Maximum number of worker nodes per AZ"
  type        = number
  default     = 4
}

variable "worker_spot_percentage" {
  description = "Percentage of spot instances in ASG (0-100)"
  type        = number
  default     = 70
  
  validation {
    condition     = var.worker_spot_percentage >= 0 && var.worker_spot_percentage <= 100
    error_message = "Spot percentage must be between 0 and 100."
  }
}