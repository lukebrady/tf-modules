output "subnet_id" {
  value = aws_subnet.nat.id
}

output "ngw_id" {
  value = aws_nat_gateway.nat.id
}

output "ngw_public_ip" {
  value = aws_eip.nat.address
}

output "vpc_id" {
  value = aws_subnet.nat.vpc_id
}

output "route_table_id" {
  value = aws_route_table.nat.id
}
