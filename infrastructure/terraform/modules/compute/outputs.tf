output "etcd_private_ips" {
  value = aws_instance.etcd[*].private_ip
}

output "pg_private_ips" {
  value = aws_instance.pg[*].private_ip
}