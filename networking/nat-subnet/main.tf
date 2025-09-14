resource "aws_subnet" "nat" {
  availability_zone       = var.availability_zone
  cidr_block              = var.cidr_block
  map_public_ip_on_launch = false
  vpc_id                  = var.vpc_id
}

resource "aws_route_table" "nat" {
  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "nat" {
  route_table_id = aws_route_table.nat.id
  subnet_id      = aws_subnet.nat.id
}

resource "aws_eip" "nat" {
  network_border_group = null
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.allocation_id
  subnet_id     = var.ngw_subnet_id
}
