variable "vpc_id" {
  type = string
}

variable "nat_instance_type" {
  description = "Instance type of the NAT Instance"
  type        = string
  default     = "c6i.large"
}

variable "ami_id" {
  description = "AMI used to deploy the NAT instance"
  type        = string
  default     = null
}

variable "nat_instance_state" {
  type    = string
  default = "running"
  validation {
    condition = contains(
      [
        "running",
        "stopped"
      ],
      var.nat_instance_state
    )
    error_message = "Must be running or stopped"
  }
}

variable "allowed_ip_addresses" {
  description = "List of IP addresses (CIDR blocks) allowed to access the server"
  type        = list(string)
  default     = [] # Empty list by default - user must specify IPs for security

  validation {
    condition = alltrue([
      for ip in var.allowed_ip_addresses : can(cidrhost(ip, 0))
    ])
    error_message = "All IP addresses must be valid CIDR blocks (e.g., '192.168.1.1/32' or '10.0.0.0/8')."
  }
}

variable "route_table_ids" {
  type    = set(string)
  default = []
}

variable "subnet_id" {
  type = string
}
