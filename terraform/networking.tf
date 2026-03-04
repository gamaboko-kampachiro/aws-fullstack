# creating vpc using var.tf file

resource "aws_vpc" "smart_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "smart-app-vpc"
  }
}

#------------------------------------------------
# creating 2 public subnet

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.smart_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = { Name = "public-subnet-1" }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.smart_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true

  tags = { Name = "public-subnet-2" }
}

#------------------------------------------------
# 2 pvt subnet

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.smart_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.region}a"

  tags = { Name = "private-subnet-1" }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.smart_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.region}b"

  tags = { Name = "private-subnet-2" }
}

#------------------------------------------------
# attaching IGW to vpc

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.smart_vpc.id

  tags = { Name = "smart-app-igw" }
}

#------------------------------------------------
# allocate and create  NAT

# 1. allocte IP

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# 2. create NAT

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_1.id

  tags = { Name = "smart-nat" }
}

#------------------------------------------------
# public route table

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.smart_vpc.id
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

#------------------------------------------------
# private route table

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.smart_vpc.id
}

resource "aws_route" "private_internet_access" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_assoc_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_assoc_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_rt.id
}