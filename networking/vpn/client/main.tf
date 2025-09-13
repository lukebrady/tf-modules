resource "aws_security_group" "vpn" {
  name_prefix = "vpn-"
  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  ingress {
    from_port = 1024
    to_port   = 65535
    protocol  = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  egress {
    from_port = 1024
    to_port   = 65535
    protocol  = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  vpc_id = var.vpc_id
}

resource "aws_ec2_client_vpn_endpoint" "vpn_endpoint" {
  description            = var.description
  server_certificate_arn = var.server_certificate_arn
  client_cidr_block      = var.client_cidr_block
  split_tunnel           = true
  security_group_ids = [
    aws_security_group.vpn.id
  ]
  vpc_id = var.vpc_id

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = var.server_certificate_arn
  }

  connection_log_options {
    enabled = false
  }
}

resource "aws_ec2_client_vpn_network_association" "vpn" {
  for_each = var.associate_subnet_ids

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn_endpoint.id
  subnet_id              = each.value
}

resource "aws_ec2_client_vpn_authorization_rule" "vpc_access" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn_endpoint.id
  description            = "Grants access to the VPC"
  target_network_cidr    = var.target_network_cidr
  authorize_all_groups   = true
}
