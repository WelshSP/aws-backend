terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

# Generate a unique master password per environment
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_instance" "this" {
  identifier             = "${var.project_name}-${var.environment}-rds"
  engine                 = "mysql"
  engine_version         = "8.4.10"
  port                   = 3306
  username               = "admin_${var.environment}"
  password               = random_password.db_password.result
  allocated_storage      = var.allocated_storage
  instance_class         = var.instance_class
  multi_az               = var.multi_az
  vpc_security_group_ids = var.vpc_security_group_ids
  db_subnet_group_name   = var.db_subnet_group_name
  backup_retention_period = var.backup_retention_period
  apply_immediately      = true
  skip_final_snapshot    = true
  allow_major_version_upgrade = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-rds"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_db_instance" "replica" {

  count = var.environment != "dev" ? 1 : 0

  identifier             = "${var.project_name}-${var.environment}-readonly-replica"
  replicate_source_db    = aws_db_instance.this.identifier 
  instance_class         = "db.t4g.micro"
  auto_minor_version_upgrade = true
  skip_final_snapshot    = true
  
  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Name        = "${var.project_name}-${var.environment}-readonly-replica"
  }
}