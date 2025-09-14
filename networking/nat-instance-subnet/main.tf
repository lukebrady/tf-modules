resource "aws_subnet" "nat" {
  availability_zone       = var.availability_zone
  cidr_block              = var.cidr_block
  map_public_ip_on_launch = false
  vpc_id                  = var.vpc_id

  tags = {
    SubnetType = "NAT-Instance"
  }
}

resource "aws_route_table" "nat" {
  vpc_id = var.vpc_id
}

resource "aws_route" "nat" {
  route_table_id         = aws_route_table.nat.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.nat.id
}

resource "aws_route_table_association" "nat" {
  route_table_id = aws_route_table.nat.id
  subnet_id      = aws_subnet.nat.id
}

resource "aws_eip" "nat" {
  network_border_group = null
}

resource "aws_security_group" "nat" {
  name_prefix = "nat-"
  description = "NAT Instance security group for subnet: ${aws_subnet.nat.id}"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = [
      var.cidr_block
    ]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
      var.cidr_block
    ]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      var.cidr_block
    ]
  }

  egress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

}

resource "aws_network_interface" "nat" {
  security_groups = [
    aws_security_group.nat.id
  ]
  source_dest_check = false
  subnet_id         = var.nat_subnet_id
}

resource "aws_instance" "nat" {
  ami               = var.ami_id == null ? data.aws_ami.ubuntu_server_2404.id : var.ami_id
  availability_zone = var.availability_zone
  instance_type     = var.nat_instance_type
  user_data         = base64encode(file("${path.module}/scripts/userdata.sh"))

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.nat.id
  }
  tags = {
    Name = "${aws_subnet.nat.id}-nat-instance"
  }
}

resource "aws_eip_association" "nat" {
  allocation_id        = aws_eip.nat.allocation_id
  network_interface_id = aws_network_interface.nat.id
}

resource "aws_ec2_instance_state" "nat" {
  instance_id = aws_instance.nat.id
  state       = var.nat_instance_state
}
