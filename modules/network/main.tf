# Project VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = merge(
    {
      Name = "vpc-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
    },
    var.common_tags
  )
}

# Private Subnets
resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  cidr_block              = element(var.public_subnet_cidrs, count.index)
  vpc_id                  = aws_vpc.main.id
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name = "public-subnet-${count.index + 1}-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
    },
    var.common_tags
  )
}

# Public Subnets
resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  vpc_id            = aws_vpc.main.id
  availability_zone = element(var.azs, count.index)

  tags = merge(
    {
      Name                     = "private-subnet-${count.index + 1}-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
      "karpenter.sh/discovery" = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}"
    },
    var.common_tags
  )
}

# Internet gateway for public subnets
resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name = "internet-gateway-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
    },
    var.common_tags
  )
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  count  = length(var.public_subnet_cidrs)
  domain = "vpc"
  tags = merge(
    {
      Name = "eip-nat-gw-${count.index + 1}-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
    },
    var.common_tags
  )
}

# NAT Gateway for private subnets
resource "aws_nat_gateway" "natgw" {
  count         = length(var.public_subnet_cidrs)
  allocation_id = element(aws_eip.nat[*].id, count.index)
  subnet_id     = element(aws_subnet.public_subnets[*].id, count.index)

  tags = merge(
    {
      Name = "nat-gw-${count.index + 1}-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
    },
    var.common_tags
  )

  depends_on = [aws_internet_gateway.gateway]
}

# Public subnet route table
resource "aws_route_table" "public_subnet_route_table" {
  count  = length(var.public_subnet_cidrs)
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name = "public-subnets-rt-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
    },
    var.common_tags
  )
}

# Public subnets routes
resource "aws_route" "public_rt" {
  count                  = length(var.public_subnet_cidrs)
  route_table_id         = aws_route_table.public_subnet_route_table[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id
}

# Public subnets route tables assocation
resource "aws_route_table_association" "public_subnet" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = element(aws_route_table.public_subnet_route_table[*].id, count.index)
}

# Private subnet route tables
resource "aws_route_table" "private_subnet_route_table" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name = "private-subnets-rt-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
    },
    var.common_tags
  )
  depends_on = [aws_nat_gateway.natgw]
}

# Private subnet route tables assocation
resource "aws_route_table_association" "private_subnet" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
  route_table_id = element(aws_route_table.private_subnet_route_table[*].id, count.index)
}

# Private subnet route table routes
resource "aws_route" "private_rt" {
  count                  = length(var.private_subnet_cidrs)
  route_table_id         = aws_route_table.private_subnet_route_table[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.natgw[count.index].id
}