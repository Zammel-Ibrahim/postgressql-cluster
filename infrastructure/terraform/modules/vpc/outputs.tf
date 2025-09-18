output "vpc_id"         { value = aws_vpc.this.id }
output "public_subnets" { value = values(aws_subnet.public)[*].id}
output "private_subnets"{ value = values(aws_subnet.private)[*].id}
output "public_route_table_id" {
  value = aws_route_table.public_rt.id
}

output "private_route_table_id" {
  value = aws_route_table.private_rt.id
}