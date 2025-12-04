# outputs.tf

# ==============================================================================
# Bastion & SSH
# ==============================================================================
output "bastion_public_ip" {
  description = "The public IP address of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "ssh_command_bastion" {
  description = "Command to SSH into the bastion host"
  value       = "ssh -i k8s-key.pem ubuntu@${aws_instance.bastion.public_ip}"
}

output "ssh_command_master_1" {
  description = "Example command to SSH into master node (run from bastion)"
  value       = "ssh ubuntu@${aws_instance.master[0].private_ip}"
}

# ==============================================================================
# Master Nodes
# ==============================================================================
output "master_private_ips" {
  description = "List of private IP addresses for master nodes"
  value       = aws_instance.master[*].private_ip
}

# ==============================================================================
# Worker Nodes (Legacy - will be replaced by ASG)
# ==============================================================================
output "worker_private_ips" {
  description = "List of private IP addresses for worker nodes"
  value       = aws_instance.worker[*].private_ip
}

# ==============================================================================
# Load Balancer
# ==============================================================================
output "control_plane_endpoint" {
  description = "The DNS name of the internal NLB for K8s control plane"
  value       = aws_lb.internal_nlb.dns_name
}

output "nlb_dns_name" {
  description = "DNS name of the Network Load Balancer"
  value       = aws_lb.internal_nlb.dns_name
}

# ==============================================================================
# VPC & Networking
# ==============================================================================
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.k8s_vpc.id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

# ==============================================================================
# EFS
# ==============================================================================
output "efs_file_system_id" {
  description = "ID of the EFS file system"
  value       = aws_efs_file_system.k8s_efs.id
}

output "efs_dns_name" {
  description = "DNS name of the EFS file system"
  value       = aws_efs_file_system.k8s_efs.dns_name
}

output "efs_mount_target_ids" {
  description = "IDs of EFS mount targets"
  value       = aws_efs_mount_target.k8s_mount_targets[*].id
}

output "efs_access_point_id" {
  description = "ID of the EFS access point"
  value       = aws_efs_access_point.k8s_access_point.id
}

# ==============================================================================
# IAM
# ==============================================================================
output "worker_node_iam_role_arn" {
  description = "ARN of the worker node IAM role"
  value       = aws_iam_role.worker_node_role.arn
}

output "worker_node_instance_profile_name" {
  description = "Name of the worker node instance profile"
  value       = aws_iam_instance_profile.worker_node_profile.name
}

output "efs_csi_policy_arn" {
  description = "ARN of the EFS CSI driver IAM policy"
  value       = aws_iam_policy.efs_csi_driver_policy.arn
}

output "alb_controller_policy_arn" {
  description = "ARN of the ALB controller IAM policy"
  value       = aws_iam_policy.alb_controller_policy.arn
}

output "cluster_autoscaler_policy_arn" {
  description = "ARN of the Cluster Autoscaler IAM policy"
  value       = aws_iam_policy.cluster_autoscaler_policy.arn
}

# ==============================================================================
# Security Groups
# ==============================================================================
output "k8s_cluster_sg_id" {
  description = "ID of the K8s cluster security group"
  value       = aws_security_group.k8s_cluster_sg.id
}

output "efs_sg_id" {
  description = "ID of the EFS security group"
  value       = aws_security_group.efs_sg.id
}

output "alb_sg_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb_sg.id
}

output "worker_asg_name" {
  description = "Name of the Auto Scaling Group for workers"
  value       = aws_autoscaling_group.worker_asg.name
}