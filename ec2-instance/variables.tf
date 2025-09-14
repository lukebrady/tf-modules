variable "name_prefix" {
  description = "Prefix for instance Name tag. Index appended automatically."
  type        = string
}

variable "ami_id" {
  description = "AMI ID to use (e.g., Ubuntu 22.04)."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
}

variable "key_name" {
  description = "Existing EC2 key pair name for SSH."
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs to attach."
  type        = list(string)
  default     = []
}

variable "subnet_ids" {
  description = "List of subnet IDs to spread instances across (round-robin)."
  type        = list(string)
}

variable "instance_count" {
  description = "Number of instances to create."
  type        = number
  default     = 1
}

variable "associate_public_ip" {
  description = "Whether to associate a public IP."
  type        = bool
  default     = false
}

variable "iam_instance_profile" {
  description = "Name of IAM instance profile to attach."
  type        = string
  default     = null
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 40
}

variable "root_volume_type" {
  description = "Root EBS volume type."
  type        = string
  default     = "gp3"
}

variable "user_data" {
  description = "Cloud-init/user-data script content."
  type        = string
  default     = ""
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default     = {}
}

