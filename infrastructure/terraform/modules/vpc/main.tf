resource "aws_vpc" "this" {
  cidr_block = var.cidr
  tags       = { Name = var.name }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
}

resource "aws_subnet" "public" {
  for_each               = toset(var.azs)
  vpc_id                 = aws_vpc.this.id
  cidr_block             = cidrsubnet(var.cidr, 8, index(var.azs, each.value))
  availability_zone      = each.value
  map_public_ip_on_launch = true
  tags                   = { Name = "${var.name}-public-${each.value}" }
}

resource "aws_subnet" "private" {
  for_each          = toset(var.azs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.cidr, 8, 100 + index(var.azs, each.value))
  availability_zone = each.value
  tags              = { Name = "${var.name}-private-${each.value}" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_rt.id
}