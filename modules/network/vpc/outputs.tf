output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = aws_vpc.this.cidr_block
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "natgw_ids" {
  description = "NAT Gateway IDs"
  value       = var.enable_nat_gateway ? aws_nat_gateway.this[*].id : []
}

output "igw_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.this.id
}
