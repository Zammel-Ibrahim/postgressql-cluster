output "etcdprivateips" {
  description = "IP privées des nœuds Etcd"
  value       = awsinstance.etcd[*].privateip
}

output "patroniprivateips" {
  description = "IP privées des nœuds Patroni"
  value       = awsinstance.patroni[*].privateip
}
`