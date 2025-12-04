# security_groups.tf

# ==============================================================================
# 1. Bastion Security Group
# ==============================================================================
resource "aws_security_group" "bastion_sg" {
  name        = "k8s-bastion-sg"
  description = "Allow SSH from anywhere"
  vpc_id      = aws_vpc.k8s_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: Consider restricting to your IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-bastion-sg"
  }
}

# ==============================================================================
# 2. Kubernetes Cluster Security Group (Masters and Workers)
# ==============================================================================
resource "aws_security_group" "k8s_cluster_sg" {
  name        = "k8s-cluster-sg"
  description = "Security group for K8s masters and workers"
  vpc_id      = aws_vpc.k8s_vpc.id

  # SSH from Bastion
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  # All internal cluster traffic
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  # K8s API access from within VPC
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # NodePort Services (30000-32767) from ALB
  ingress {
    from_port       = 30000
    to_port         = 32767
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-cluster-sg"
  }
}

# ==============================================================================
# 3. EFS Security Group
# ==============================================================================
resource "aws_security_group" "efs_sg" {
  name        = "k8s-efs-sg"
  description = "Allow NFS traffic from K8s worker nodes"
  vpc_id      = aws_vpc.k8s_vpc.id

  # Allow NFS from K8s cluster
  ingress {
    description     = "Allow NFS from K8s nodes"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.k8s_cluster_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-efs-sg"
  }
}

# ==============================================================================
# 4. ALB Security Group (Public)
# ==============================================================================
resource "aws_security_group" "alb_sg" {
  name        = "k8s-alb-public-sg"
  description = "Security group for public ALB"
  vpc_id      = aws_vpc.k8s_vpc.id

  # HTTP from Internet
  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS from Internet (if you add SSL later)
  ingress {
    description = "Allow HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound to K8s worker nodes (NodePort range)
  egress {
    description     = "Allow traffic to K8s NodePort services"
    from_port       = 30000
    to_port         = 32767
    protocol        = "tcp"
    security_groups = [aws_security_group.k8s_cluster_sg.id]
  }

  # Allow all outbound (needed for health checks)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-alb-public-sg"
  }
}