output "mysql_sg_id" {
  value = aws_security_group.mysql_sg.id
}

output "mysql_cluster_id" {
  value = aws_rds_cluster.mysql_cluster.id
}

output "mysql_cluster_endpoint" {
  value = aws_rds_cluster.mysql_cluster.endpoint
  ephemeral = true
}

output "mysql_cluster_master_username" {
  value = aws_rds_cluster.mysql_cluster.master_username
  ephemeral = true
}

output "mysql_cluster_master_password" {
  value = aws_rds_cluster.mysql_cluster.master_password
  ephemeral = true
}

output "mysql_cluster_master_database" {
  value = aws_rds_cluster.mysql_cluster.database_name
  ephemeral = true
}