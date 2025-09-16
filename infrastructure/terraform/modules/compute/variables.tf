variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "etcd_count" {
  description = "Number of etcd nodes to create"
  type        = number
}

variable "pg_count" {
  description = "Number of Postgres nodes to create"
  type        = number
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for naming EC2 instances"
  type        = string
}

variable "ssh_key_name" {
  description = "SSH key pair name to assign"
  type        = string
}