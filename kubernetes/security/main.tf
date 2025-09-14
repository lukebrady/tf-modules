terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_security_group" "control_plane" {
  name        = "${var.cluster_name}-control-plane"
  description = "Control plane SG for Kubernetes"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.cluster_name}-control-plane" })
}

resource "aws_security_group" "worker" {
  name        = "${var.cluster_name}-worker"
  description = "Worker SG for Kubernetes"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.cluster_name}-worker" })
}

# SSH to both groups
resource "aws_security_group_rule" "ssh_control_plane" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.ssh_ingress_cidrs
  security_group_id = aws_security_group.control_plane.id
}

resource "aws_security_group_rule" "ssh_worker" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.ssh_ingress_cidrs
  security_group_id = aws_security_group.worker.id
}

# API server access
resource "aws_security_group_rule" "api_from_cidrs" {
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = var.api_ingress_cidrs
  security_group_id = aws_security_group.control_plane.id
}

resource "aws_security_group_rule" "api_from_workers" {
  type                     = "ingress"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.worker.id
  security_group_id        = aws_security_group.control_plane.id
}

# etcd peer + client (control-plane internal)
resource "aws_security_group_rule" "etcd_peer" {
  type                     = "ingress"
  from_port                = 2379
  to_port                  = 2380
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.control_plane.id
  security_group_id        = aws_security_group.control_plane.id
}

# Kubelet API from control plane
resource "aws_security_group_rule" "kubelet_from_cp" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.control_plane.id
  security_group_id        = aws_security_group.worker.id
}

# NodePort range
resource "aws_security_group_rule" "nodeport_from_cidrs" {
  type              = "ingress"
  from_port         = 30000
  to_port           = 32767
  protocol          = "tcp"
  cidr_blocks       = var.nodeport_ingress_cidrs
  security_group_id = aws_security_group.worker.id
}

# Intra-cluster communication (allow all between groups)
resource "aws_security_group_rule" "intra_worker" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.worker.id
  security_group_id        = aws_security_group.worker.id
}

resource "aws_security_group_rule" "cp_from_cp" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.control_plane.id
  security_group_id        = aws_security_group.control_plane.id
}

