variable "description" {
  type    = string
  default = "Client VPN Endpoint"
}

variable "client_cidr_block" {
  type    = string
  default = "192.168.0.0/22"
}

variable "associate_subnet_ids" {
  type    = map(string)
  default = {}
}
variable "vpc_id" {
  type = string
}

variable "server_certificate_arn" {
  type = string
}

variable "target_network_cidr" {
  type    = string
  default = "10.0.0.0/24"
}
