output "bastion_ip" {
  description = "Bastion public IP"
  value       = aws_instance.bastion.public_ip
}

output "etcd_private_ips" {
  value = concat(
    module.compute_db1.etcd_private_ips,
    module.compute_db2.etcd_private_ips
  )
}

output "pg_private_ips" {
  value = concat(
    module.compute_db1.pg_private_ips,
    module.compute_db2.pg_private_ips
  )
}

output "ssh_private_key_path" {
  description = "Path to SSH private key for Ansible"
  value       = var.ssh_private_key_path
}