# 1. Bastion Host
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu_22_04.id
  instance_type               = var.bastion_instance_type
  key_name                    = "k8s-key"
  subnet_id                   = aws_subnet.public[0].id # Place in the first public subnet
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true # It needs a public IP

  tags = {
    Name = "k8s-bastion-host"
  }
}

# 2. K8s Master Nodes
resource "aws_instance" "master" {
  count         = 3
  ami           = data.aws_ami.ubuntu_22_04.id
  instance_type = var.master_instance_type
  key_name      = "k8s-key"
  # Spread masters across the 3 private subnets
  subnet_id     = aws_subnet.private[count.index].id 
  vpc_security_group_ids = [aws_security_group.k8s_cluster_sg.id]

  tags = {
    Name = "k8s-master-${count.index + 1}"
    Role = "k8s-master"
  }
}

