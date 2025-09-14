resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_s3_bucket" "vpc" {
  count  = var.enable_flow_logs ? 1 : 0
  bucket = "${aws_vpc.vpc.id}-flow-logs"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "vpc" {
  count  = var.enable_flow_logs ? 1 : 0
  bucket = aws_s3_bucket.vpc[0].bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "vpc" {
  count                   = var.enable_flow_logs ? 1 : 0
  bucket                  = aws_s3_bucket.vpc[0].bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_flow_log" "vpc" {
  count                = var.enable_flow_logs ? 1 : 0
  log_destination      = aws_s3_bucket.vpc[0].arn
  log_destination_type = "s3"
  traffic_type         = "REJECT"
  vpc_id               = aws_vpc.vpc.id
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}
