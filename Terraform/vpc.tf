# Create the VPC
resource "aws_vpc" "k8s_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "k8s-vpc"
  }
}

# Create 3 Public Subnets, one in each AZ
resource "aws_subnet" "public" {
  count                   = 3
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "k8s-public-subnet-${count.index + 1}"
  }
}

# Create 3 Private Subnets, one in each AZ
resource "aws_subnet" "private" {
  count             = 3
  vpc_id            = aws_vpc.k8s_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 3) # Offset from public
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "k8s-private-subnet-${count.index + 1}"
  }
}

# Create the Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.k8s_vpc.id

  tags = {
    Name = "k8s-igw"
  }
}

# Create a Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.k8s_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "k8s-public-rt"
  }
}

# Associate Public Route Table with Public Subnets
resource "aws_route_table_association" "public" {
  count          = 3
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Create 1 Elastic IPs for the 3 NAT Gateways
resource "aws_eip" "nat" {
  count = 1
  domain   = "vpc"

  tags = {
    Name = "k8s-nat-eip-${count.index + 1}"
  }
}

# Create 1 NAT Gateway in the first Public Subnet
resource "aws_nat_gateway" "nat" {
  count         = 1
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "k8s-nat-gw-${count.index + 1}"
  }
}

# Create 3 Private Route Tables, one for each Private Subnet
resource "aws_route_table" "private_rt" {
  count  = 3
  vpc_id = aws_vpc.k8s_vpc.id

  # Route traffic to the NAT Gateway in the *same AZ*
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = {
    Name = "k8s-private-rt-${count.index + 1}"
  }
}

# Associate Private Route Tables with Private Subnets
resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_rt[count.index].id
}