# asg.tf

# ==============================================================================
# Launch Template (Defines the configuration of the Worker Nodes)
# ==============================================================================
resource "aws_launch_template" "worker_lt" {
  name_prefix   = "k8s-worker-lt-"
  image_id      = data.aws_ami.ubuntu_22_04.id
  instance_type = var.worker_instance_type
  key_name      = var.key_name

  # Attach the IAM Profile we created in iam-irsa.tf
  # This gives the node permission for EFS, ALB, and Autoscaling
  iam_instance_profile {
    name = aws_iam_instance_profile.worker_node_profile.name
  }

  # Network settings
  vpc_security_group_ids = [aws_security_group.k8s_cluster_sg.id]

  # Block Device (Storage)
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 20
      volume_type = "gp3"
    }
  }

  # Tagging instances created by this template
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "k8s-worker-node"
      Role = "k8s-worker"
      # Tags required for K8s Cluster Autoscaler discovery later
      "k8s.io/cluster-autoscaler/enabled" = "true"
      "k8s.io/cluster-autoscaler/${var.project_name}" = "owned"
    }
  }

  # Base64 encoded user_data (Empty for now, we will add the Join script later)
  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo "Worker Node Initializing..."
              EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ==============================================================================
# Auto Scaling Group (Manages the count and lifecycle of Workers)
# ==============================================================================
resource "aws_autoscaling_group" "worker_asg" {
  name                = "k8s-worker-asg"
  vpc_zone_identifier = aws_subnet.private[*].id # Deploy in Private Subnets
  
  # Scaling limits
  min_size         = var.worker_asg_min_size
  max_size         = var.worker_asg_max_size
  desired_capacity = var.worker_asg_desired_size

  # Use the Launch Template created above
  launch_template {
    id      = aws_launch_template.worker_lt.id
    version = "$Latest"
  }

  # Health Checks
  health_check_type         = "EC2"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "k8s-worker-asg-node"
    propagate_at_launch = true
  }

  # Refresh instances if the Launch Template changes
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
}