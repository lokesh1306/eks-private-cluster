data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_rds_cluster" "mysql_cluster" {
  cluster_identifier                  = var.rds_cluster_identifier
  engine                              = var.rds_engine
  engine_version                      = var.rds_engine_version
  database_name                       = var.rds_database_name
  master_username                     = var.rds_master_username
  master_password                     = var.rds_master_password
  backup_retention_period             = var.rds_backup_retention_period
  preferred_backup_window             = var.rds_preferred_backup_window
  storage_encrypted                   = true
  db_cluster_instance_class           = var.db_cluster_instance_class
  storage_type                        = var.rds_storage_type
  allocated_storage                   = var.rds_allocated_storage
  iops                                = var.rds_iops
  vpc_security_group_ids              = [aws_security_group.mysql_sg.id]
  db_subnet_group_name                = aws_db_subnet_group.mysql_subnet_group.name
  iam_database_authentication_enabled = true
  availability_zones                  = var.azs
}

# resource "aws_rds_cluster_instance" "mysql_read_replica_1" {
#   identifier             = "mysql-cluster-instance-2"
#   cluster_identifier     = aws_rds_cluster.mysql_cluster.id
#   instance_class         = "d3.t3.medium"
#   engine                 = aws_rds_cluster.mysql_cluster.engine
#   engine_version         = aws_rds_cluster.mysql_cluster.engine_version
#   publicly_accessible    = false
#   auto_minor_version_upgrade = true
# }

# resource "aws_rds_cluster_instance" "mysql_read_replica_2" {
#   identifier             = "mysql-cluster-instance-3"
#   cluster_identifier     = aws_rds_cluster.mysql_cluster.id
#   instance_class         = "d3.t3.medium"
#   engine                 = aws_rds_cluster.mysql_cluster.engine
#   engine_version         = aws_rds_cluster.mysql_cluster.engine_version
#   publicly_accessible    = false
#   auto_minor_version_upgrade = true
# }

resource "aws_db_subnet_group" "mysql_subnet_group" {
  name       = "mysql-subnet-group-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
  subnet_ids = var.private_subnet_ids
  tags = merge(
    {
      Name = "mysql-subnet-group-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
    },
    var.common_tags
  )
}

resource "aws_security_group" "mysql_sg" {
  name        = "mysql-sg-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
  vpc_id      = var.vpc_id
  tags = merge(
    {
      Name = "mysql-sg-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
    },
    var.common_tags
  )
}

resource "aws_security_group_rule" "ec2_egress" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = var.remote_state.outputs.ec2_sg
  source_security_group_id = aws_security_group.mysql_sg.id
}

resource "aws_security_group_rule" "mysql_ingress_ec2" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.mysql_sg.id
  source_security_group_id = var.remote_state.outputs.ec2_sg
}

resource "aws_security_group_rule" "mysql_ingress_eks" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  security_group_id = aws_security_group.mysql_sg.id
  cidr_blocks       = [var.vpc_cidr]
}