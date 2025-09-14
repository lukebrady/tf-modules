terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

locals {
  name = var.cluster_name
  tags = merge(var.tags, { "kubernetes.io/cluster" = var.cluster_name })
}

module "sg" {
  source                 = "../security"
  cluster_name           = var.cluster_name
  vpc_id                 = var.vpc_id
  ssh_ingress_cidrs      = var.ssh_ingress_cidrs
  api_ingress_cidrs      = var.api_ingress_cidrs
  nodeport_ingress_cidrs = var.nodeport_ingress_cidrs
  tags                   = local.tags
}

resource "random_id" "suffix" {
  byte_length = 3
}

locals {
  artifact_bucket_name = coalesce(var.artifact_bucket_name, "${var.cluster_name}-artifacts-${random_id.suffix.hex}")
}

resource "aws_s3_bucket" "artifacts" {
  count  = var.create_artifact_bucket && var.artifact_bucket_name == null ? 1 : 0
  bucket = local.artifact_bucket_name
  tags   = local.tags
}

data "aws_iam_policy_document" "bucket_access" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${local.artifact_bucket_name}",
      "arn:aws:s3:::${local.artifact_bucket_name}/*"
    ]
  }
}

resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
  tags = local.tags
}

resource "aws_iam_policy" "bucket" {
  name   = "${var.cluster_name}-bucket-access"
  policy = data.aws_iam_policy_document.bucket_access.json
}

resource "aws_iam_role_policy_attachment" "node_bucket" {
  role       = aws_iam_role.node.name
  policy_arn = aws_iam_policy.bucket.arn
}

resource "aws_iam_instance_profile" "node" {
  name = "${var.cluster_name}-node-profile"
  role = aws_iam_role.node.name
}

locals {
  cp_user_data = templatefile("${path.module}/templates/bootstrap-control-plane.sh.tpl", {
    CLUSTER_NAME = var.cluster_name,
    BUCKET_NAME  = local.artifact_bucket_name,
    REGION       = var.region
  })
  worker_user_data = templatefile("${path.module}/templates/bootstrap-worker.sh.tpl", {
    CLUSTER_NAME = var.cluster_name,
    BUCKET_NAME  = local.artifact_bucket_name,
    REGION       = var.region
  })
}

module "control_plane" {
  source               = "../../ec2-instance"
  name_prefix          = "${var.cluster_name}-cp"
  ami_id               = var.ami_id == null ? data.aws_ami.ubuntu_server_2404.id : var.ami_id
  instance_type        = var.control_plane_instance_type
  security_group_ids   = [module.sg.control_plane_sg_id]
  subnet_ids           = var.control_plane_subnet_ids
  count                = var.control_plane_count
  associate_public_ip  = var.associate_public_ip
  iam_instance_profile = aws_iam_instance_profile.node.name
  user_data            = local.cp_user_data
  root_volume_size     = 40
  tags                 = local.tags
}

module "workers" {
  source               = "../../ec2-instance"
  name_prefix          = "${var.cluster_name}-worker"
  ami_id               = var.ami_id == null ? data.aws_ami.ubuntu_server_2404.id : var.ami_id
  instance_type        = var.worker_instance_type
  security_group_ids   = [module.sg.worker_sg_id]
  subnet_ids           = var.worker_subnet_ids
  count                = var.worker_count
  associate_public_ip  = var.associate_public_ip
  iam_instance_profile = aws_iam_instance_profile.node.name
  user_data            = local.worker_user_data
  root_volume_size     = 40
  tags                 = local.tags
}

output "artifact_bucket_name" {
  value       = local.artifact_bucket_name
  description = "S3 bucket used to exchange bootstrap artifacts (join command)."
}

output "control_plane_private_ips" {
  value       = flatten(module.control_plane[*].private_ips)
  description = "Control plane private IPs."
}

output "worker_private_ips" {
  value       = flatten(module.workers[*].private_ips)
  description = "Worker private IPs."
}

output "control_plane_public_ips" {
  value       = flatten(module.control_plane[*].public_ips)
  description = "Control plane public IPs (if assigned)."
}

output "worker_public_ips" {
  value       = flatten(module.workers[*].public_ips)
  description = "Worker public IPs (if assigned)."
}
