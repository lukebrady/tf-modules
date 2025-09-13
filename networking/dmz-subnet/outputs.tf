output "subnet_id" {
  value = aws_subnet.dmz.id
}

output "vpc_id" {
  value = aws_subnet.dmz.vpc_id
}

output "route_table_id" {
  value = aws_route_table.dmz.id
}
