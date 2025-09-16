variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "db_vpc_cidrs" {
  description = "CIDRs for the two DB VPCs"
  type        = list(string)
  default     = ["10.10.0.0/16", "10.20.0.0/16"]
}

variable "mgmt_vpc_cidr" {
  description = "CIDR for management VPC"
  default     = "10.30.0.0/16"
}

variable "azs" {
  description = "List of AZs to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.medium"
}

variable "etcd_count" {
  description = "Number of etcd nodes"
  default     = 3
}

variable "ssh_key_name" {
  description = "Name for the AWS key pair"
  type        = string
  default     = "deployer-key"
}

variable "ssh_public_key" {
  description = "Public SSH key material"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Local path to private key for Ansible"
  type        = string
  default     = "~/.ssh/deployer-key.pem"
}