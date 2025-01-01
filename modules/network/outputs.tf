output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnet_ids" {
  value = aws_subnet.private_subnets[*].id
}

output "private_subnet_route_tables" {
  value = aws_route_table.private_subnet_route_table[*].id
}