# Generates a secure 4096-bit RSA cryptographic key
resource "tls_private_key" "developer_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Registers the public key component with AWS
resource "aws_key_pair" "deployer_key" {
  key_name   = "${var.project_name}-developer-access-key"
  public_key = tls_private_key.developer_key.public_key_openssh
}


# Find the latest official Ubuntu 24.04 LTS AMI id automatically
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical's official AWS Owner ID
}

# DEV SERVER
resource "aws_instance" "dev_app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small" # 2 vCPU, 2GB RAM - cheap but snappy enough for live dev work
  key_name               = aws_key_pair.deployer_key.key_name

  # Drop it into the Dev Network & Dev Firewall Gate
  subnet_id              = aws_subnet.public["dev"].id # Placing in AZ1 subnet space
  vpc_security_group_ids = [aws_security_group.dev_compute_sg.id]

  user_data = file("${path.module}/server-setup.sh")

  tags = {
    Name        = "${var.project_name}-dev-app-server"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# STAGING SERVER
resource "aws_instance" "staging_app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  key_name               = aws_key_pair.deployer_key.key_name

  subnet_id              = aws_subnet.public["staging"].id
  vpc_security_group_ids = [aws_security_group.staging_compute_sg.id]

  user_data = file("${path.module}/server-setup.sh")

  tags = {
    Name        = "${var.project_name}-staging-app-server"
    Environment = "staging"
    ManagedBy   = "terraform"
  }
}

# PROD SERVER
resource "aws_instance" "prod_app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium" # 2 vCPU, 4GB RAM - dedicated grunt for live client loads
  key_name               = aws_key_pair.deployer_key.key_name

  subnet_id              = aws_subnet.public["prod"].id
  vpc_security_group_ids = [aws_security_group.prod_compute_sg.id]

  user_data = file("${path.module}/server-setup.sh")

  tags = {
    Name        = "${var.project_name}-prod-app-server"
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}


# PERMANENT DEV IP
resource "aws_eip" "dev_static_ip" {
  instance = aws_instance.dev_app.id
  domain   = "vpc"
  tags     = { Name = "${var.project_name}-dev-static-ip", Environment = "dev" }
}

# PERMANENT STAGING IP
resource "aws_eip" "staging_static_ip" {
  instance = aws_instance.staging_app.id
  domain   = "vpc"
  tags     = { Name = "${var.project_name}-staging-static-ip", Environment = "staging" }
}

# PERMANENT PRODUCTION IP
resource "aws_eip" "prod_static_ip" {
  instance = aws_instance.prod_app.id
  domain   = "vpc"
  tags     = { Name = "${var.project_name}-prod-static-ip", Environment = "prod" }
}

# --- OUTPUTS TO DISPLAY THE IPS ---
output "dev_public_ip" {
  value = aws_eip.dev_static_ip.public_ip
}

output "staging_public_ip" {
  value = aws_eip.staging_static_ip.public_ip
}

output "prod_public_ip" {
  value = aws_eip.prod_static_ip.public_ip
}