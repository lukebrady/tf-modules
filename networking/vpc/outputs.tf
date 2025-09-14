output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "vpc_arn" {
  value = aws_vpc.vpc.arn
}

output "cidr_block" {
  value = aws_vpc.vpc.cidr_block
}

output "igw_id" {
  value = aws_internet_gateway.igw.id
}

output "igw_arn" {
  value = aws_internet_gateway.igw.arn
}
