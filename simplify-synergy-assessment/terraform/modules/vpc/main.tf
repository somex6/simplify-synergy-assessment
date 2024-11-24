locals {
  len_public_subnets  = max(length(var.public_subnets))
  len_private_subnets = max(length(var.private_subnets))
  max_subnet_length = max(
    local.len_private_subnets,
    local.len_public_subnets
  )
}

################################################################################
# VPC
################################################################################

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  instance_tenancy     = var.instance_tenancy
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge({ "Name" = var.vpc_name }, var.tags)

}

################################################################################
# Publiс Subnets
################################################################################

locals {
  create_public_subnets = local.len_public_subnets > 0
}

resource "aws_subnet" "public" {
  count = local.create_public_subnets && (!var.one_nat_gateway_per_az || local.len_public_subnets >= length(var.a_zones)) ? local.len_public_subnets : 0

  availability_zone       = length(regexall("^[a-z]{2}-", element(var.a_zones, count.index))) > 0 ? element(var.a_zones, count.index) : null
  availability_zone_id    = length(regexall("^[a-z]{2}-", element(var.a_zones, count.index))) == 0 ? element(var.a_zones, count.index) : null
  cidr_block              = element(concat(var.public_subnets, [""]), count.index)
  map_public_ip_on_launch = var.map_public_ip_on_launch
  vpc_id                  = aws_vpc.this.id

  tags = var.tags
}

locals {
  num_public_route_tables = var.create_multiple_public_route_tables ? local.len_public_subnets : 1
}

resource "aws_route_table" "public" {
  count = local.create_public_subnets ? local.num_public_route_tables : 0

  vpc_id = aws_vpc.this.id

  tags = var.tags
}

resource "aws_route_table_association" "public" {
  count = local.create_public_subnets ? local.len_public_subnets : 0

  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = element(aws_route_table.public[*].id, var.create_multiple_public_route_tables ? count.index : 0)
}

resource "aws_route" "public_internet_gateway" {
  count = local.create_public_subnets && var.create_igw ? local.num_public_route_tables : 0

  route_table_id         = aws_route_table.public[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id

  timeouts {
    create = "5m"
  }
}

################################################################################
# Private Subnets
################################################################################

locals {
  create_private_subnets = local.len_private_subnets > 0
}

resource "aws_subnet" "private" {
  count = local.create_private_subnets ? local.len_private_subnets : 0

  availability_zone    = length(regexall("^[a-z]{2}-", element(var.a_zones, count.index))) > 0 ? element(var.a_zones, count.index) : null
  availability_zone_id = length(regexall("^[a-z]{2}-", element(var.a_zones, count.index))) == 0 ? element(var.a_zones, count.index) : null
  cidr_block           = element(concat(var.private_subnets, [""]), count.index)
  vpc_id               = aws_vpc.this.id

  tags = var.tags
}

# There are as many routing tables as the number of NAT gateways
resource "aws_route_table" "private" {
  count = local.create_private_subnets && local.len_private_subnets > 0 ? local.nat_gateway_count : 0

  vpc_id = aws_vpc.this.id

  tags = var.tags
}

resource "aws_route_table_association" "private" {
  count = local.create_private_subnets ? local.len_private_subnets : 0

  subnet_id = element(aws_subnet.private[*].id, count.index)
  route_table_id = element(
    aws_route_table.private[*].id,
    var.single_nat_gateway ? 0 : count.index,
  )
}

################################################################################
# Internet Gateway
################################################################################

resource "aws_internet_gateway" "this" {
  count = local.create_public_subnets && var.create_igw ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = var.tags
}

################################################################################
# NAT Gateway
################################################################################

locals {
  nat_gateway_count = var.single_nat_gateway ? 1 : var.one_nat_gateway_per_az ? length(var.a_zones) : local.max_subnet_length
  nat_gateway_ips   = var.reuse_nat_ips ? var.external_nat_ip_ids : aws_eip.nat[*].id
}

resource "aws_eip" "nat" {
  count = var.enable_nat_gateway && !var.reuse_nat_ips ? local.nat_gateway_count : 0

  domain = "vpc"

  tags = var.tags

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = var.enable_nat_gateway ? local.nat_gateway_count : 0

  allocation_id = element(
    local.nat_gateway_ips,
    var.single_nat_gateway ? 0 : count.index,
  )
  subnet_id = element(
    aws_subnet.public[*].id,
    var.single_nat_gateway ? 0 : count.index,
  )

  tags = var.tags

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route" "private_nat_gateway" {
  count = var.enable_nat_gateway && var.create_private_nat_gateway_route ? local.nat_gateway_count : 0

  route_table_id         = element(aws_route_table.private[*].id, count.index)
  destination_cidr_block = var.nat_gateway_destination_cidr_block
  nat_gateway_id         = element(aws_nat_gateway.this[*].id, count.index)

  timeouts {
    create = "5m"
  }
}