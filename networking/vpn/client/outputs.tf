output "dns_name" {
  value = aws_ec2_client_vpn_endpoint.vpn_endpoint.dns_name
}

output "client_cidr_block" {
  value = var.client_cidr_block
}
