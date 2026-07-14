
# 1. GENERATE A SECURE PASSWORD PROGRAMMATICALLY

# Generates a random 16-character string to use as the master password
resource "random_password" "db_master_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}



# 2. CREATE THE AWS SECRETS MANAGER CONTAINER

resource "aws_secretsmanager_secret" "db_secret" {
  name        = "${var.project_name}-prod-db-credentials"
  description = "Encryption vault for live Production RDS credentials"
  
  # Protects against accidental deletion during teardowns
  recovery_window_in_days = 7 
}



# 3. POPULATE THE VAULT WITH KEY/VALUE DATA

resource "aws_secretsmanager_secret_version" "db_secret_payload" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  
  # Encodes the database credentials into JSON format
  secret_string = jsonencode({
    username = "admin_vault"
    password = random_password.db_master_password.result
    engine   = "mysql"
    port     = 3306
  })
}



# 4. REFERENCE THE VAULT INSIDE YOUR DB CONFIGURATION

# This decodes the secret string so the actual database creation block can use it securely
locals {
  db_credentials = jsondecode(aws_secretsmanager_secret_version.db_secret_payload.secret_string)
}

