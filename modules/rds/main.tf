data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Aurora Cluster
resource "aws_rds_cluster" "mysql_cluster" {
  cluster_identifier                  = var.rds_cluster_identifier
  engine                              = var.rds_engine
  engine_version                      = var.rds_engine_version
  database_name                       = var.rds_database_name
  master_username                     = var.master_username
  manage_master_user_password         = true
  backup_retention_period             = var.rds_backup_retention_period
  preferred_backup_window             = var.rds_preferred_backup_window
  storage_encrypted                   = true
  storage_type                        = var.rds_storage_type
  # allocated_storage                   = var.rds_allocated_storage
  # db_cluster_instance_class           = var.db_cluster_instance_class
  vpc_security_group_ids              = [aws_security_group.mysql_sg.id]
  db_subnet_group_name                = aws_db_subnet_group.mysql_subnet_group.name
  skip_final_snapshot                 = true
  iam_database_authentication_enabled = true
  availability_zones                  = var.azs
  enabled_cloudwatch_logs_exports     = ["audit", "error", "general", "slowquery"]
  tags = merge(
    {
      Name = "rds-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
    },
    var.common_tags
  )
}

# writer instance
resource "aws_rds_cluster_instance" "writer" {
  identifier         = "writer-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
  cluster_identifier = aws_rds_cluster.mysql_cluster.id
  instance_class     = var.db_cluster_instance_class
  engine             = var.rds_engine
  engine_version     = var.rds_engine_version
}

# reader instances
resource "aws_rds_cluster_instance" "readers" {
  count              = 2  
  identifier         = "reader-${count.index}-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
  cluster_identifier = aws_rds_cluster.mysql_cluster.id
  instance_class     = var.db_cluster_instance_class
  engine             = var.rds_engine
  engine_version     = var.rds_engine_version
  promotion_tier     = count.index + 2
}

# Subnet group
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

# SG for the DB
resource "aws_security_group" "mysql_sg" {
  name   = "mysql-sg-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
  vpc_id = var.vpc_id
  tags = merge(
    {
      Name = "mysql-sg-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
    },
    var.common_tags
  )
}

# EC2 egress rule for MySQL
resource "aws_security_group_rule" "ec2_egress" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = var.remote_state.outputs.ec2_sg
  source_security_group_id = aws_security_group.mysql_sg.id
}

# MySQL ingress for EC2
resource "aws_security_group_rule" "mysql_ingress_ec2" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.mysql_sg.id
  source_security_group_id = var.remote_state.outputs.ec2_sg
}
