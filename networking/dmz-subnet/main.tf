resource "aws_subnet" "dmz" {
  availability_zone       = var.availability_zone
  cidr_block              = var.cidr_block
  map_public_ip_on_launch = true
  vpc_id                  = var.vpc_id
}

resource "aws_route_table" "dmz" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.igw_id
  }
}

resource "aws_route_table_association" "dmz" {
  route_table_id = aws_route_table.dmz.id
  subnet_id      = aws_subnet.dmz.id
}

