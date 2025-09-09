provider "aws" {
  region = var.region
}

#VPC Etcd
resource "aws_vpc" "etcd" {
  cidrblock           = var.vpccidr_etcd
  enablednshostnames = true
  tags = { Name = "vpc-etcd" }
}

#VPC Patroni
resource "aws_vpc" "patroni" {
  cidrblock           = var.vpccidr_patroni
  enablednshostnames = true
  tags = { Name = "vpc-patroni" }
}

#Subnets / Internet GW / Routes pour chaque VPC (privé + public si besoin)
module "subnets_etcd" {
  source          = "terraform-aws-modules/vpc/aws//modules/subnets"
  version         = "4.0.0"
  vpcid          = awsvpc.etcd.id
  availabilityzones = data.awsavailability_zones.available.names[0:2]
  private_subnets = ["10.0.1.0/24","10.0.2.0/24"]
}

module "subnets_patroni" {
  source          = "terraform-aws-modules/vpc/aws//modules/subnets"
  version         = "4.0.0"
  vpcid          = awsvpc.patroni.id
  availabilityzones = data.awsavailability_zones.available.names[0:2]
  private_subnets = ["10.1.1.0/24","10.1.2.0/24"]
}

data "awsavailabilityzones" "available" {}

#Security Group commun
resource "awssecuritygroup" "ha_sg" {
  name        = "ha-cluster-sg"
  description = "Ouverture ports 2379-2380,5432,8008,VRRP(112)"
  vpcid      = awsvpc.patroni.id

  ingress {
    description      = "Etcd client"
    from_port        = 2379
    to_port          = 2379
    protocol         = "tcp"
    cidrblocks      = [var.vpccidretcd,var.vpccidr_patroni]
  }
  ingress {
    description = "Etcd peer"
    from_port   = 2380
    to_port     = 2380
    protocol    = "tcp"
    cidrblocks = [var.vpccidr_etcd]
  }
  ingress {
    description = "Postgres"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidrblocks = [var.vpccidr_patroni]
  }
  ingress {
    description = "Patroni REST"
    from_port   = 8008
    to_port     = 8008
    protocol    = "tcp"
    cidrblocks = [var.vpccidr_patroni]
  }
  ingress {
    description = "VRRP (Keepalived)"
    from_port   = 112
    to_port     = 112
    protocol    = "icmp"
    cidrblocks = [var.vpccidr_patroni]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Keypair
resource "awskeypair" "admin" {
  keyname   = "haadmin"
  publickey = file("~/.ssh/idrsa.pub")
}

#Lancement des nœuds Etcd
resource "aws_instance" "etcd" {
  count                       = var.instancecountetcd
  ami                         = data.aws_ami.rocky.id
  instancetype               = var.instancetype
  vpcsecuritygroupids      = [awssecuritygroup.hasg.id]
  subnetid                   = module.subnetsetcd.privatesubnets[count.index % length(module.subnetsetcd.private_subnets)]
  keyname                    = awskeypair.admin.keyname
  associatepublicip_address = false
  tags = { Name = "etcd-${count.index+1}" }
}

#Lancement des nœuds Patroni
resource "aws_instance" "patroni" {
  count                       = var.instancecountpatroni
  ami                         = data.aws_ami.rocky.id
  instancetype               = var.instancetype
  vpcsecuritygroupids      = [awssecuritygroup.hasg.id]
  subnetid                   = module.subnetspatroni.privatesubnets[count.index % length(module.subnetspatroni.private_subnets)]
  keyname                    = awskeypair.admin.keyname
  associatepublicip_address = false
  tags = { Name = "patroni-${count.index+1}" }
}

#AMI Rocky Linux 9.x
data "aws_ami" "rocky" {
  most_recent = true
  owners      = ["679593333241"] # Rocky Linux Official
  filter {
    name   = "name"
    values = ["Rocky-9--x86_64"]
  }
}
