resource "aws_security_group" "etcd_sg" {
  name        = "${var.name_prefix}-etcd-sg"
  vpc_id      = var.vpc_id
  description = "Etcd nodes"
  ingress {
    from_port       = 2379
    to_port         = 2380
    protocol        = "tcp"
    security_groups = [aws_security_group.pg_sg.id]
  }
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    #security_groups = [var.bastion_sg_id]
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH from bastion"
  }
  
  ingress {
    from_port       = -1
    to_port         = -1
    protocol        = "icmp"
    #security_groups = [var.bastion_sg_id]
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow ping from all instances"
  }
  
  egress { 
    from_port = 0 
    to_port = 0 
    protocol = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
  }
}


resource "aws_security_group" "pg_sg" {
  name        = "${var.name_prefix}-pg-sg"
  vpc_id      = var.vpc_id
  description = "Patroni/Postgres"
  ingress {
    #security_groups = aws_security_group.pg_sg.id
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
  }
  ingress {
    #security_groups = aws_security_group.pg_sg.id
    from_port       = 9000
    to_port         = 9001
    protocol        = "tcp"
  }
  egress {
    from_port = 0 
    to_port = 0 
    protocol = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
  }
}

resource "aws_instance" "etcd" {
  count                  = var.etcd_count
  ami                    = "ami-0b09ffb6d8b58ca91"
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.etcd_sg.id]
  subnet_id              = element(var.private_subnets, count.index % length(var.private_subnets))
  tags                   = { Name = "${var.name_prefix}-etcd-${count.index+1}" }
}

resource "aws_instance" "pg" {
  count                  = var.pg_count
  ami                    = "ami-0b09ffb6d8b58ca91"
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.pg_sg.id]
  subnet_id              = element(var.private_subnets, count.index % length(var.private_subnets))
  tags                   = { Name = "${var.name_prefix}-pg-${count.index+1}" }
}