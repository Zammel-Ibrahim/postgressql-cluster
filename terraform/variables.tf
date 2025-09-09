variable "region" {
  description = "AWS région"
  type        = string
  default     = "eu-west-3"
}

variable "vpccidretcd" {
  description = "CIDR VPC Etcd"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpccidrpatroni" {
  description = "CIDR VPC Patroni"
  type        = string
  default     = "10.1.0.0/16"
}

variable "instancecountetcd" {
  description = "Nombre de nœuds Etcd"
  type        = number
  default     = 3
}

variable "instancecountpatroni" {
  description = "Nombre de nœuds Patroni"
  type        = number
  default     = 2
}

variable "instance_type" {
  description = "Type d’instance EC2 pour tous les serveurs"
  type        = string
  default     = "t3.medium"
}
