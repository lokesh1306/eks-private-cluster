data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_rds_cluster" "mysql_cluster" {
  cluster_identifier                  = "mysql-multi-az-cluster"
  engine                              = "mysql"
  engine_version                      = "8.0.40"
  database_name                       = "test"
  master_username                     = "admin"
  master_password                     = "password"
  backup_retention_period             = 7
  preferred_backup_window             = "07:00-09:00"
  storage_encrypted                   = true
  db_cluster_instance_class           = "db.c6gd.medium"
  storage_type                        = "io1"
  allocated_storage                   = 100
  iops                                = 1000
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
  name       = "mysql-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "MySQL Subnet Group"
  }
}

resource "aws_security_group" "mysql_sg" {
  name        = "mysql-security-group"
  description = "Allow MySQL access"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "ec2_egress" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = var.remote_state.outputs.ec2_sg
  source_security_group_id = aws_security_group.mysql_sg.id
}

# EKS Ingress SG for SSM
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

resource "aws_iam_policy" "rds_connect_policy" {
  name = "rds-eks-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "rds-db:connect"
        Resource = "arn:aws:rds-db:${var.region}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_rds_cluster.mysql_cluster.id}/testuser"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_rds_connect_policy" {
  policy_arn = aws_iam_policy.rds_connect_policy.arn
  role       = var.app_role_name
}

provider "mysql" {
  endpoint = aws_rds_cluster.mysql_cluster.endpoint
  username = aws_rds_cluster.mysql_cluster.master_username
  password = aws_rds_cluster.mysql_cluster.master_password
}

resource "mysql_user" "app_user" {
  user        = "testuser"
  host        = "%"
  auth_plugin = "mysql_native_password"
}

resource "mysql_grant" "app_user_privileges" {
  user       = mysql_user.app_user.user
  host       = mysql_user.app_user.host
  database   = aws_rds_cluster.mysql_cluster.database_name
  privileges = ["SELECT", "INSERT", "UPDATE", "DELETE", "CREATE", "DROP", "INDEX", "ALTER"]
}