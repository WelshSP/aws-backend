output "db_instance_id" {
  description = "The RDS instance identifier"
  value       = aws_db_instance.this.identifier
}

output "db_instance_endpoint" {
  description = "The connection endpoint (host:port)"
  value       = aws_db_instance.this.endpoint
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.this.arn
}

output "db_password" {
  description = "The generated master password for this environment's RDS instance"
  value       = random_password.db_password.result
  sensitive   = true
}
