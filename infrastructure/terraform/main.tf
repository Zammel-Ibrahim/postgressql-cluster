provider "aws" {
  region = var.aws_region
}

# Create an AWS key pair from provided public key
resource "aws_key_pair" "deployer" {
  key_name   = var.ssh_key_name
  public_key = file("~/.ssh/deployer-key.pub")
}

# 1) Mgmt VPC (for bastion)
module "vpc_mgmt" {
  source = "./modules/vpc"
  name   = "mgmt-vpc"
  cidr   = var.mgmt_vpc_cidr
  azs    = var.azs
}

# 2) Two DB VPCs
module "vpc_db1" {
  source = "./modules/vpc"
  name   = "db1-vpc"
  cidr   = var.db_vpc_cidrs[0]
  azs    = var.azs
}
module "vpc_db2" {
  source = "./modules/vpc"
  name   = "db2-vpc"
  cidr   = var.db_vpc_cidrs[1]
  azs    = var.azs
}

# 3) VPC Peering: Mgmt ↔ DB1 & Mgmt ↔ DB2
resource "aws_vpc_peering_connection" "mgmt_db1" {
  vpc_id      = module.vpc_mgmt.vpc_id
  peer_vpc_id = module.vpc_db1.vpc_id
  auto_accept = false
  peer_region = var.aws_region
  tags = { Name = "peering-mgmt-db1" }
}
resource "aws_vpc_peering_connection_accepter" "mgmt_db1_accept" {
  vpc_peering_connection_id = aws_vpc_peering_connection.mgmt_db1.id
  auto_accept               = true
}
resource "aws_vpc_peering_connection" "mgmt_db2" {
  vpc_id      = module.vpc_mgmt.vpc_id
  peer_vpc_id = module.vpc_db2.vpc_id
  tags        = { Name = "peering-mgmt-db2" }
}
resource "aws_vpc_peering_connection_accepter" "mgmt_db2_accept" {
  vpc_peering_connection_id = aws_vpc_peering_connection.mgmt_db2.id
  auto_accept               = true
}

# 4) EC2 + Etcd in each DB VPC
module "compute_db1" {
  source         = "./modules/compute"
  vpc_id         = module.vpc_db1.vpc_id
  public_subnets = module.vpc_db1.public_subnets
  private_subnets= module.vpc_db1.private_subnets
  etcd_count     = var.etcd_count
  pg_count       = 2
  instance_type  = var.instance_type
  name_prefix    = "db1"
  ssh_key_name   = aws_key_pair.deployer.key_name
}
module "compute_db2" {
  source         = "./modules/compute"
  vpc_id         = module.vpc_db2.vpc_id
  public_subnets = module.vpc_db2.public_subnets
  private_subnets= module.vpc_db2.private_subnets
  etcd_count     = 0
  pg_count       = 2
  instance_type  = var.instance_type
  name_prefix    = "db2"
  ssh_key_name   = aws_key_pair.deployer.key_name
}

# 5) Bastion in Mgmt VPC
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  vpc_id      = module.vpc_mgmt.vpc_id
  description = "Allow SSH from anywhere"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "bastion" {
  ami                    = "ami-0b09ffb6d8b58ca91"
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  subnet_id              = module.vpc_mgmt.public_subnets[0]
  tags = { Name = "bastion" }
}