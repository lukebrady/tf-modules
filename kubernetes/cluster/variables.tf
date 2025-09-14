variable "cluster_name" {
  description = "Cluster name used for tagging and S3 pathing."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "control_plane_subnet_ids" {
  description = "Subnets for control plane instances."
  type        = list(string)
}

variable "worker_subnet_ids" {
  description = "Subnets for worker instances."
  type        = list(string)
}

variable "control_plane_count" {
  description = "Number of control plane instances. For automated bootstrap, 1 is recommended."
  type        = number
  default     = 1
}

variable "worker_count" {
  description = "Number of worker nodes."
  type        = number
  default     = 2
}

variable "ami_id" {
  description = "AMI used to deploy the NAT instance"
  type        = string
  default     = null
}

variable "control_plane_instance_type" {
  description = "Instance type for control plane."
  type        = string
  default     = "t3.medium"
}

variable "worker_instance_type" {
  description = "Instance type for workers."
  type        = string
  default     = "t3.large"
}

variable "ssh_key_name" {
  description = "EC2 key pair name."
  type        = string
}

variable "associate_public_ip" {
  description = "Attach public IPs to instances."
  type        = bool
  default     = true
}

variable "ssh_ingress_cidrs" {
  description = "Allowed CIDRs for SSH."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "api_ingress_cidrs" {
  description = "Allowed CIDRs for Kubernetes API (6443)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "nodeport_ingress_cidrs" {
  description = "Allowed CIDRs for NodePort services."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "region" {
  description = "AWS region for CLI operations inside instances."
  type        = string
}

variable "create_artifact_bucket" {
  description = "Whether to create an S3 bucket for bootstrap artifacts. If false, provide artifact_bucket_name."
  type        = bool
  default     = true
}

variable "artifact_bucket_name" {
  description = "Existing S3 bucket name to store join script."
  type        = string
  default     = null
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default     = {}
}

