variable "environment" {
  description = "Deployment environment (e.g. dev, prod)"
  type        = string
}

variable "allocated_storage" {
  description = "Allocated storage in gigabytes"
  type        = number
}

variable "instance_class" {
  description = "RDS instance type (e.g. db.t4g.small)"
  type        = string
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment for high availability"
  type        = bool
  default     = false
}

variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs to associate with the instance"
  type        = list(string)
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "hub-cloud"
}

variable "db_subnet_group_name" {
  description = "Name of the DB subnet group to deploy into (optional)"
  type        = string
  default     = null
}

variable "backup_retention_period" {
  description = "The days to retain backups. Must be 1+ to enable read replicas."
  type        = number
  default     = 0 # Defaults to off for dev/sandbox environments
}
