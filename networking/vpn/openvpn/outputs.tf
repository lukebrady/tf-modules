output "instance_id" {
  value = aws_instance.vpn.id
}

output "public_ip" {
  value = aws_eip.vpn.address
}
