variable "name" {
  description = "Name of the RDS instance or Aurora cluster"
  type        = string
}

variable "engine" {
  description = "Database engine for the RDS instance (e.g. postgres, mysql)"
  type        = string
  default     = "postgres"
}
variable "engine_cluster" {
  description = "Database engine for the Aurora cluster (e.g. aurora-postgresql, aurora-mysql)"
  type        = string
  default     = "aurora-postgresql"
}
variable "aurora_replica_count" {
  description = "Number of Aurora read replicas (excluding the primary writer)"
  type        = number
  default     = 1
}

variable "aurora_instance_count" {
  description = "Total number of Aurora instances in the cluster (1 primary + N replicas)"
  type        = number
  default     = 2
}
variable "engine_version" {
  description = "Engine version for the standalone RDS instance"
  type        = string
  default     = "14.7"
}

variable "instance_class" {
  description = "DB instance class (e.g. db.t3.micro, db.t3.medium)"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GiB for the standalone RDS instance"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Name of the initial database to create"
  type        = string
}

variable "username" {
  description = "Master username for the database"
  type        = string
}

variable "password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  description = "ID of the VPC where the database will be deployed"
  type        = string
}

variable "subnet_private_ids" {
  description = "List of private subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "subnet_public_ids" {
  description = "List of public subnet IDs used when publicly_accessible is true"
  type        = list(string)
}

variable "publicly_accessible" {
  description = "Whether the database is publicly accessible from the internet"
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment for high availability"
  type        = bool
  default     = false
}

variable "parameters" {
  description = "Map of DB parameter key-value pairs to apply via the parameter group"
  type        = map(string)
  default     = {}
}

variable "use_aurora" {
  description = "If true, deploy an Aurora cluster; if false, deploy a standalone RDS instance"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "The number of days to retain backups for the RDS instance or Aurora cluster"
  type        = number
  default     = 7
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to reach the DB port (e.g. VPC CIDR)"
  type        = list(string)
  default     = []
}

variable "db_port" {
  description = "Database port (e.g. 5432 for PostgreSQL, 3306 for MySQL)"
  type        = number
}

variable "tags" {
  description = "Additional tags to apply to all RDS resources"
  type        = map(string)
  default     = {}
}

variable "parameter_group_family_aurora" {
  description = "Parameter group family for the Aurora cluster (e.g. aurora-postgresql15)"
  type        = string
  default     = "aurora-postgresql15"
}
variable "engine_version_cluster" {
  description = "Engine version for the Aurora cluster"
  type        = string
  default     = "15.3"
}
variable "parameter_group_family_rds" {
  description = "Parameter group family for the standalone RDS instance (e.g. postgres15, mysql8.0)"
  type        = string
  default     = "postgres15"
}
