output "endpoint" {
  description = "Writer endpoint (Aurora cluster endpoint or RDS instance endpoint)"
  value = var.use_aurora ? (
    aws_rds_cluster.this[0].endpoint
  ) : (
    aws_db_instance.standard[0].address
  )
}

output "reader_endpoint" {
  description = "Reader endpoint (Aurora only; equals writer endpoint for RDS)"
  value = var.use_aurora ? (
    aws_rds_cluster.this[0].reader_endpoint
  ) : (
    aws_db_instance.standard[0].address
  )
}

output "port" {
  description = "Database port"
  value = var.use_aurora ? (
    aws_rds_cluster.this[0].port
  ) : (
    aws_db_instance.standard[0].port
  )
}

output "security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}

output "subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.default.name
}
