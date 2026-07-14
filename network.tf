# THE ISOLATED VPCS
resource "aws_vpc" "environment_vpc" {
  for_each             = toset(var.environments) # Loops through ["dev", "staging", "prod"]
  cidr_block           = var.vpc_cidr_blocks[each.key]
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-${each.key}-vpc"
    Environment = each.key
  }
}

# INTERNET GATEWAYS (ONE PER VPC)
resource "aws_internet_gateway" "igw" {
  for_each = toset(var.environments)
  vpc_id   = aws_vpc.environment_vpc[each.key].id 

  tags = {
    Name      = "${var.project_name}-${each.key}-igw"
    ManagedBy = "terraform"
  }
}

# MISSING PUBLIC APP SUBNETS (Where the EC2 instances go!)
resource "aws_subnet" "public" {
  for_each                = aws_vpc.environment_vpc
  vpc_id                  = each.value.id
  cidr_block              = cidrsubnet(each.value.cidr_block, 8, 10) # Carves out a public pool (e.g., 10.x.10.0/24)
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true 

  tags = {
    Name        = "${var.project_name}-${each.key}-public-app-subnet"
    Environment = each.key
  }
}

# PUBLIC ROUTE TABLES
resource "aws_route_table" "public" {
  for_each = toset(var.environments)
  vpc_id   = aws_vpc.environment_vpc[each.key].id 

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[each.key].id
  }

  tags = {
    Name = "${var.project_name}-${each.key}-public-rt"
  }
}

# ASSOCIATE THE ROUTE TABLES TO THE NEW PUBLIC SUBNETS
resource "aws_route_table_association" "public" {
  for_each       = toset(var.environments)
  route_table_id = aws_route_table.public[each.key].id
  subnet_id      = aws_subnet.public[each.key].id
}

# ISOLATED PRIVATE DATABASE SUBNETS

# AWS RDS Multi-AZ require subnets across at least 2 separate Availability Zones
resource "aws_subnet" "database_subnet_az1" {
  for_each          = aws_vpc.environment_vpc
  vpc_id            = each.value.id
  
  # Offsets the CIDR block to create a distinct sub-pool (e.g., 10.10.50.0/24)
  cidr_block        = cidrsubnet(each.value.cidr_block, 8, 50) 
  availability_zone = "us-west-2a" # Seattle/Spokane region low-latency zones

  tags = {
    Name        = "${var.project_name}-${each.key}-db-subnet-az1"
    Environment = each.key
  }
}

resource "aws_subnet" "database_subnet_az2" {
  for_each          = aws_vpc.environment_vpc
  vpc_id            = each.value.id
  cidr_block        = cidrsubnet(each.value.cidr_block, 8, 51) # Second pool (e.g., 10.10.51.0/24)
  availability_zone = "us-west-2b"

  tags = {
    Name        = "${var.project_name}-${each.key}-db-subnet-az2"
    Environment = each.key
  }
}



# THE DB SUBNET GROUP

# This defines the physical pool of IP space where RDS can safely deploy instances
resource "aws_db_subnet_group" "rds_subnet_group" {
  for_each   = aws_vpc.environment_vpc
  name       = "${var.project_name}-${each.key}-rds-subnet-group"
  subnet_ids = [
    aws_subnet.database_subnet_az1[each.key].id,
    aws_subnet.database_subnet_az2[each.key].id
  ]

  tags = {
    Name        = "${var.project_name}-${each.key}-db-subnet-group"
    Environment = each.key
  }
}