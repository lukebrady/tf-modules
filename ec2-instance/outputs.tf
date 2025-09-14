output "instance_ids" {
  description = "IDs of created instances."
  value       = aws_instance.this[*].id
}

output "private_ips" {
  description = "Private IPs of created instances."
  value       = aws_instance.this[*].private_ip
}

output "public_ips" {
  description = "Public IPs of created instances (if assigned)."
  value       = aws_instance.this[*].public_ip
}

output "subnet_ids_used" {
  description = "Subnets used for each instance index."
  value       = [for i in aws_instance.this : i.subnet_id]
}

