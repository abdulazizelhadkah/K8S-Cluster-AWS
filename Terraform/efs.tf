# efs.tf - EFS File System for Kubernetes Persistent Storage

# Define the EFS File System
resource "aws_efs_file_system" "k8s_efs" {
  creation_token   = "k8s-cluster-efs"
  performance_mode = "generalPurpose" # Good for most workloads
  throughput_mode  = "bursting"       # Scales with storage size
  encrypted        = true

  # Enable lifecycle management to transition to IA after 30 days
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  # Enable automatic backups
  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = {
    Name        = "k8s-cluster-efs"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Create Mount Targets in each private subnet (one per AZ for HA)
resource "aws_efs_mount_target" "k8s_mount_targets" {
  count           = 3
  file_system_id  = aws_efs_file_system.k8s_efs.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs_sg.id]
}


# Backup policy for EFS (optional but recommended)
resource "aws_efs_backup_policy" "k8s_efs_backup" {
  file_system_id = aws_efs_file_system.k8s_efs.id

  backup_policy {
    status = "ENABLED" # Enables automatic daily backups
  }
}