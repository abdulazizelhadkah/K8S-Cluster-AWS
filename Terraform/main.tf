# main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Get the list of Availability Zones in the region
data "aws_availability_zones" "available" {
  state = "available"
}

# Get the latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu_22_04" {
  most_recent = true
  owners      = ["099720109477"] # This is Canonical's AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "local_file" "ansible_inventory" {
  # Place inventory.ini in the PARENT directory
  filename = "${path.module}/../inventory.ini"
  
  # Find the template file INSIDE the current directory
  content = templatefile("${path.module}/inventory.tpl", {
    bastion_public_ip = aws_instance.bastion.public_ip,
    master_ips        = aws_instance.master.*.private_ip,
    worker_ips        = aws_instance.worker.*.private_ip
  })
}
