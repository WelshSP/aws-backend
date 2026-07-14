
# 1. DEVELOPMENT ENVIRONMENT

resource "aws_security_group" "dev_compute_sg" {
  name        = "dev-compute-security-group"
  description = "Assigned to Dev instances and agents"
  vpc_id      = aws_vpc.environment_vpc["dev"].id
}

resource "aws_security_group" "dev_db_sg" {
  name        = "dev-database-security-group"
  vpc_id      = aws_vpc.environment_vpc["dev"].id

  ingress {
    description     = "Allow inbound traffic strictly from Dev compute"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.dev_compute_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



# 2. STAGING ENVIRONMENT

resource "aws_security_group" "staging_compute_sg" {
  name        = "staging-compute-security-group"
  vpc_id      = aws_vpc.environment_vpc["staging"].id
}

resource "aws_security_group" "staging_db_sg" {
  name        = "staging-database-security-group"
  vpc_id      = aws_vpc.environment_vpc["staging"].id

  ingress {
    description     = "Allow staging compute to query the staging database"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.staging_compute_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



# 3. PRODUCTION ENVIRONMENT

resource "aws_security_group" "prod_compute_sg" {
  name        = "prod-compute-security-group"
  vpc_id      = aws_vpc.environment_vpc["prod"].id
}

resource "aws_security_group" "prod_db_sg" {
  name        = "prod-database-security-group"
  vpc_id      = aws_vpc.environment_vpc["prod"].id

  ingress {
    description     = "Strictly limit live database access to production compute"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.prod_compute_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}