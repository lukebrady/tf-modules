variable "vpc_id" {
  description = "VPC ID for security groups."
  type        = string
}

variable "cluster_name" {
  description = "Identifier for the Kubernetes cluster to prefix resource names."
  type        = string
}

variable "ssh_ingress_cidrs" {
  description = "CIDR blocks allowed to SSH."
  type        = list(string)
  default     = []
}

variable "api_ingress_cidrs" {
  description = "CIDR blocks allowed to access the Kubernetes API (6443)."
  type        = list(string)
  default     = []
}

variable "nodeport_ingress_cidrs" {
  description = "CIDR blocks allowed to access NodePort range."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}

