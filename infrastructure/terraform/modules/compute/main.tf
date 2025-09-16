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
  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_security_group" "pg_sg" {
  name        = "${var.name_prefix}-pg-sg"
  vpc_id      = var.vpc_id
  description = "Patroni/Postgres"
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.pg_sg.id]
  }
  ingress {
    from_port       = 9000
    to_port         = 9001
    protocol        = "tcp"
    security_groups = [aws_security_group.pg_sg.id]
  }
  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_instance" "etcd" {
  count                  = var.etcd_count
  ami                    = "<YOUR_ETCD_AMI>"
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.etcd_sg.id]
  subnet_id              = element(var.private_subnets, count.index % length(var.private_subnets))
  tags                   = { Name = "${var.name_prefix}-etcd-${count.index+1}" }
}

resource "aws_instance" "pg" {
  count                  = var.pg_count
  ami                    = "<YOUR_PG_18_AMI>"
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.pg_sg.id]
  subnet_id              = element(var.private_subnets, count.index % length(var.private_subnets))
  tags                   = { Name = "${var.name_prefix}-pg-${count.index+1}" }
}