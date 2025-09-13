variable "availability_zone" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ami_id" {
  description = "AMI used to deploy the NAT instance"
  type        = string
  default     = null
}

variable "nat_instance_type" {
  description = "Instance type of the NAT Instance"
  type        = string
  default     = "c6i.large"
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

variable "nat_subnet_id" {
  type = string
}
