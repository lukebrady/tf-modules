terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  subnets = var.subnet_ids
}

resource "aws_instance" "this" {
  count         = var.instance_count
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = local.subnets[count.index % length(local.subnets)]
  key_name      = var.key_name

  vpc_security_group_ids      = var.security_group_ids
  associate_public_ip_address = var.associate_public_ip
  monitoring                  = var.enable_monitoring

  iam_instance_profile = var.iam_instance_profile

  user_data = var.user_data

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name = format("%s-%02d", var.name_prefix, count.index + 1)
  })
}

