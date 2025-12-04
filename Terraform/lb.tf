# lb.tf

# Create the internal Network Load Balancer
resource "aws_lb" "internal_nlb" {
  name               = "k8s-master-nlb"
  internal           = true
  load_balancer_type = "network"
  
  # Place the NLB in all 3 private subnets for HA
  subnets = aws_subnet.private.*.id

  tags = {
    Name = "k8s-master-nlb"
  }
}

# Create the Target Group for the K8s API (port 6443)
resource "aws_lb_target_group" "k8s_api_tg" {
  name     = "k8s-api-tg"
  port     = 6443
  protocol = "TCP"
  vpc_id   = aws_vpc.k8s_vpc.id
  
  # Health checks for the K8s API
  health_check {
    protocol = "TCP"
    port     = "6443"
  }
}

# Create the NLB Listener
resource "aws_lb_listener" "k8s_api_listener" {
  load_balancer_arn = aws_lb.internal_nlb.arn
  port              = 6443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s_api_tg.arn
  }
}

# Attach the 3 master nodes to the Target Group
resource "aws_lb_target_group_attachment" "master_tg_attach" {
  count            = 3
  target_group_arn = aws_lb_target_group.k8s_api_tg.arn
  target_id        = aws_instance.master[count.index].id
  port             = 6443
}

