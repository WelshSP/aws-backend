# HUB Cloud AWS Backend Infrastructure

## 1. The Problem Statement: The Context

Manual environment setup for dev, staging, and production inevitably leads to configuration drift, inconsistent security group rules, forgotten backups, leaked database credentials, and fragile hand-tuned servers. This repository codifies the entire HUB Software Venture backend footprint in Terraform so every VPC, subnet, security group, EC2 instance, MySQL database, and secret is provisioned identically every time, with environment isolation, encrypted credentials, and reproducible compute images built in.

## 2. The Architecture: The Logic

### Networking layer

- **`aws_vpc`**: One isolated VPC per environment (`dev`, `staging`, `prod`) using non-overlapping CIDR blocks (`10.10.0.0/16`, `10.20.0.0/16`, `10.30.0.0/16`). This prevents cross-environment traffic and makes routing predictable.
- **`aws_internet_gateway`**: One IGW per VPC so the public app subnets can reach the internet for package updates and health checks.
- **`aws_subnet.public`**: Public app subnets with `map_public_ip_on_launch = true`, carved via `cidrsubnet(..., 8, 10)` from each VPC. This is where the Ubuntu application servers live.
- **`aws_subnet.database_subnet_az1` / `aws_subnet.database_subnet_az2`**: Isolated database subnets in `us-west-2a` and `us-west-2b` (offsets `50` and `51`). RDS Multi-AZ requires subnets in at least two AZs, so two independent pools are created.
- **`aws_route_table` / `aws_route_table_association`**: Public route tables direct outbound traffic through the IGW and are explicitly associated with the public subnets.
- **`aws_db_subnet_group`**: Combines the two database subnets per environment into a named group that RDS can consume for placement and failover.

### Compute layer

- **`tls_private_key` + `aws_key_pair`**: A 4096-bit RSA key is generated in Terraform and registered with AWS as the developer access key. This avoids ad-hoc key management and gives operators a single artifact to download.
- **`data.aws_ami.ubuntu`**: Always resolves the latest official Ubuntu 24.04 LTS AMI (`099720109477`) so launches are reproducible and up to date.
- **`aws_instance.dev_app` / `staging_app` / `prod_app`**: Per-environment EC2 instances running Nginx and PHP 8.4 (installed via `server-setup.sh`). Dev and staging use `t3.small`; production uses `t3.medium` for client-facing load.
- **`aws_eip`**: Permanent Elastic IPs are attached to each app server so DNS records and developer SSH targets remain stable across instance restarts.
- **`server-setup.sh`**: Bootstraps each instance with Nginx, PHP 8.4-FPM, and common PHP extensions (`mysql`, `xml`, `mbstring`, `curl`, `zip`, `bcmath`).

### Data layer

- **RDS module (`modules/rds`)**: Creates MySQL 8.4.10 `aws_db_instance` resources per environment, automatically generates a unique `admin_<env>` password, and tags everything for cost allocation.
  - **Production**: `db.t4g.medium`, `multi_az = true`, 50 GB storage, 7-day backup retention, plus a read replica for horizontal read scaling.
  - **Staging**: Dedicated read replica sourced from production (`db.t4g.small`) for realistic test data without risking the live database.
  - **Development**: `db.t4g.small`, 20 GB, single-AZ to keep sandbox costs low while still matching the production engine.

### Security layer

- **`aws_security_group.dev_compute_sg` / `staging_compute_sg` / `prod_compute_sg`**: Per-environment compute security groups attached to the corresponding EC2 instances.
- **`aws_security_group.dev_db_sg` / `staging_db_sg` / `prod_db_sg`**: Database security groups that allow inbound MySQL (port 3306) *only* from the matching environment's compute security group, enforcing least-privilege network access.

### Secrets layer

- **`random_password.db_master_password`**: A 16-character random string with a controlled special-character set, removing manual password generation.
- **`aws_secretsmanager_secret` + `aws_secretsmanager_secret_version`**: Stores the production database username, password, engine, and port in AWS Secrets Manager with a 7-day recovery window, preventing accidental credential loss or plaintext exposure.
- **`locals.db_credentials`**: Decodes the secret for use by the RDS configuration so credentials never appear in plain text in the Terraform source.

## 3. How to Run It: The Execution

### Prerequisites

1. Install [Terraform](https://developer.hashicorp.com/terraform/install) (this repo uses the AWS, `random`, and `tls` providers).
2. Install and configure the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html):
   ```bash
   aws configure
   ```
3. Confirm your AWS credentials and default region (`us-west-2`) are active.

### Initialize the project

Run this from the repository root (`c:\Users\ShaunWelsh\Projects\HUB Software Venture\aws-backend` on Windows, or the equivalent path on Linux/macOS):

```bash
terraform init
```

### Review the execution plan

```bash
terraform plan
```

### Apply the infrastructure

```bash
terraform apply -auto-approve
```

Terraform will create three VPCs, the networking stack, three EC2 instances, the RDS instances, and the secrets vault. Expect this to take several minutes because RDS provisioning and Elastic IP attachment are asynchronous.

### Extract the developer SSH key

After `apply` completes, capture the generated private key to a `.pem` file and lock down its permissions:

```bash
terraform output -raw developer_private_key > hub-cloud-developer.pem
chmod 400 hub-cloud-developer.pem
```

On Windows PowerShell you can instead run:

```powershell
terraform output -raw developer_private_key | Out-File -FilePath hub-cloud-developer.pem -Encoding utf8
```

### Connect to the servers

Use the public IP outputs shown at the end of `apply`:

```bash
ssh -i hub-cloud-developer.pem ubuntu@<DEV_PUBLIC_IP>
```

Replace `<DEV_PUBLIC_IP>` with the value of the `dev_public_ip` output. Use `staging_public_ip` or `prod_public_ip` for the other environments.

### Destroy everything (optional)

```bash
terraform destroy -auto-approve
```

> **Warning:** `destroy` will remove all EC2 instances, RDS databases, and Elastic IPs. The production secret in AWS Secrets Manager has a 7-day recovery window, so it will be scheduled for deletion rather than removed immediately.
