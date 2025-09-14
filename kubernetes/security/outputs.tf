output "control_plane_sg_id" {
  description = "Security group ID for control plane."
  value       = aws_security_group.control_plane.id
}

output "worker_sg_id" {
  description = "Security group ID for workers."
  value       = aws_security_group.worker.id
}

