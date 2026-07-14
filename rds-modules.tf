module "db_production" {
  source                 = "./modules/rds"
  environment            = "prod"
  allocated_storage      = 50
  instance_class         = "db.t4g.medium"
  multi_az               = true
  vpc_security_group_ids = [aws_security_group.prod_db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group["prod"].name
  backup_retention_period = 7
}

resource "aws_db_instance" "staging_read_replica" {
  identifier            = "staging-readonly-replica"
  replicate_source_db   = module.db_production.db_instance_id
  instance_class        = "db.t4g.small"
  apply_immediately     = true
  skip_final_snapshot   = true
}

module "db_development" {
  source                 = "./modules/rds"
  environment            = "dev"
  allocated_storage      = 20
  instance_class         = "db.t4g.small"
  multi_az               = false
  vpc_security_group_ids = [aws_security_group.dev_db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group["dev"].name
}
