resource "aws_eip" "vpn" {
  network_border_group = null
}

resource "aws_security_group" "vpn" {
  name_prefix = "vpn-"
  description = "VPN Instance for VPC: ${var.vpc_id}"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 1194
    to_port   = 1194
    protocol  = "udp"
    cidr_blocks = var.allowed_ip_addresses
  }

  ingress {
    from_port = 1194
    to_port   = 1194
    protocol  = "tcp"
    cidr_blocks = var.allowed_ip_addresses
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "10.0.0.0/24"
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
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "10.0.0.0/24",
    ]
  }

}

resource "aws_network_interface" "vpn" {
  security_groups = [
    aws_security_group.vpn.id
  ]
  source_dest_check = false
  subnet_id         = var.subnet_id
}

resource "aws_instance" "vpn" {
  ami           = var.ami_id == null ? data.aws_ami.ubuntu_server_2404.id : var.ami_id
  instance_type = var.nat_instance_type
  user_data = base64encode(file("${path.module}/scripts/userdata.sh"))

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.vpn.id
  }
  tags = {
    Name = "${var.vpc_id}-vpn-instance"
  }
}

resource "aws_eip_association" "vpn" {
  allocation_id        = aws_eip.vpn.allocation_id
  network_interface_id = aws_network_interface.vpn.id
}

resource "aws_ec2_instance_state" "vpn" {
  instance_id = aws_instance.vpn.id
  state       = var.nat_instance_state
}

resource "aws_route" "vpn" {
  for_each               = var.route_table_ids
  route_table_id         = each.value
  network_interface_id   = aws_network_interface.vpn.id
  destination_cidr_block = "10.8.0.0/24"
}
