output "mysql_sg_id" {
  value = aws_security_group.mysql_sg.id
}

output "mysql_cluster_id" {
  value = aws_rds_cluster.mysql_cluster.id
}

output "mysql_cluster_endpoint" {
  value = aws_rds_cluster.mysql_cluster.endpoint
}

output "mysql_cluster_database_name" {
  value = aws_rds_cluster.mysql_cluster.database_name
}