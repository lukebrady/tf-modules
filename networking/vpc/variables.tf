variable "cidr_block" {
  type    = string
  default = "10.0.0.0/24"
}

variable "enable_dns_hostnames" {
  type    = bool
  default = true
}

variable "enable_dns_support" {
  type    = bool
  default = true
}

variable "enable_network_address_usage_metrics" {
  type    = bool
  default = false
}

variable "enable_flow_logs" {
  type    = bool
  default = false
}
