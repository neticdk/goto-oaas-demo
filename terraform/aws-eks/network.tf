resource "aws_vpc" "eks" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags                 = merge({ Name = "eks-network"}, local.common_tags)
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.eks.id
  tags   = merge({ Name = "eks-gateway"}, local.common_tags)
}

resource "aws_route_table" "gw_route_table" {
  vpc_id = aws_vpc.eks.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = merge({ Name = "eks-internet-route"}, local.common_tags)
}

resource "aws_subnet" "public_subnet" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.eks.id
  map_public_ip_on_launch = true
  cidr_block              = cidrsubnet(var.public_subnet_cidr, 3, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags                    = merge({ Name = "eks-public" }, local.common_tags)
}

resource "aws_route_table_association" "public_subnet_to_public" {
  count          = length(data.aws_availability_zones.available.names)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.gw_route_table.id
}

resource "aws_subnet" "node_subnet" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.eks.id
  map_public_ip_on_launch = false
  cidr_block              = cidrsubnet(var.node_subnet_cidr, 3, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags                    = merge({ Name = "eks-nodes" }, local.common_tags)
}

resource "aws_eip" "nat" {
  tags = local.common_tags
}

resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet[0].id
  tags          = merge({ Name = "eks-nat" }, local.common_tags)
  depends_on    = [aws_internet_gateway.gw]
}

resource "aws_route_table" "nat_route_table" {
  vpc_id = aws_vpc.eks.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw.id
  }
  tags = merge({ Name = "eks-nat-route"}, local.common_tags)
}

resource "aws_route_table_association" "node_subnet_to_public_subnet" {
  count          = length(data.aws_availability_zones.available.names)
  subnet_id      = aws_subnet.node_subnet[count.index].id
  route_table_id = aws_route_table.nat_route_table.id
}
