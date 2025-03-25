provider "aws" {
  region = local.region
}

data "aws_availability_zones" "available" {}

locals {
  name   = "complete-mysql"
  region = "us-east-1"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Name       = local.name
    Example    = local.name
    Repository = "https://github.com/terraform-aws-modules/terraform-aws-rds"
  }
}

################################################################################
# Access keys
################################################################################

resource "random_password" "db_password" {
  length  = 16
  special = true
}

resource "random_id" "secret_suffix" {
  byte_length = 8
}

resource "aws_secretsmanager_secret" "rds_password" {
  name        = "${local.name}-rds-password-${random_id.secret_suffix.hex}"
  description = "RDS credentials for MySQL database"
}

resource "aws_secretsmanager_secret_version" "rds_password_version" {
  secret_id     = aws_secretsmanager_secret.rds_password.id
  secret_string = jsonencode({
    username = "admin"
    password = "AdminAdmin123"
  })
}

################################################################################
# RDS Module
################################################################################

module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = local.name

  # All available versions: http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html#MySQL.Concepts.VersionMgmt
  engine               = "mysql"
  engine_version       = "8.0"
  family               = "mysql8.0" # DB parameter group
  major_engine_version = "8.0"      # DB option group
  instance_class       = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100

  db_name  = "completeMysql"
  username = jsondecode(aws_secretsmanager_secret_version.rds_password_version.secret_string).username
  password = jsondecode(aws_secretsmanager_secret_version.rds_password_version.secret_string).password
  manage_master_user_password = false
  port     = 3306

  multi_az               = false
  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.rds_security_group.security_group_id]

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["general"]
  create_cloudwatch_log_group     = true

  skip_final_snapshot = true
  deletion_protection = false

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]

  tags = local.tags
  db_instance_tags = {
    "Sensitive" = "high"
  }
  db_option_group_tags = {
    "Sensitive" = "low"
  }
  db_parameter_group_tags = {
    "Sensitive" = "low"
  }
  db_subnet_group_tags = {
    "Sensitive" = "high"
  }
  cloudwatch_log_group_tags = {
    "Sensitive" = "high"
  }

 storage_encrypted = false
 kms_key_id = null

}


################################################################################
# Supporting Resources
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs              = local.azs
  public_subnets   = [cidrsubnet(local.vpc_cidr, 8, 0), cidrsubnet(local.vpc_cidr, 8, 1), cidrsubnet(local.vpc_cidr, 8, 5), cidrsubnet(local.vpc_cidr, 8, 6)]
  private_subnets  = [cidrsubnet(local.vpc_cidr, 8, 2)]
  database_subnets = [cidrsubnet(local.vpc_cidr, 8, 3), cidrsubnet(local.vpc_cidr, 8, 4)]

  create_database_subnet_group = true
  create_igw = true
  create_multiple_public_route_tables = true

  tags = local.tags
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = local.name
  description = "Security group allowing access on HTTP, HTTPS, SSH, and custom Node.js port"
  vpc_id      = module.vpc.vpc_id

  # Ingress rules
  ingress_with_cidr_blocks = [
    # Allow SSH access
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH access"
      cidr_blocks = "0.0.0.0/0"  # String, not a list
    },
    # Allow HTTPS access (port 443)
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS access"
      cidr_blocks = "0.0.0.0/0"
    },
    # Allow HTTP access (port 80)
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP access"
      cidr_blocks = "0.0.0.0/0"
    },
    # Allow access to port 3030 for your Node.js app
    {
      from_port   = 3030
      to_port     = 3030
      protocol    = "tcp"
      description = "Node.js app access"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  # Explicit egress rules
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"  # Allows all protocols
      description = "Allow all outbound traffic"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = local.tags
  
}

module "rds_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "rds-security-group"
  description = "Security group for RDS MySQL Database"
  vpc_id      = module.vpc.vpc_id

  # Ingress rule to allow MySQL access from the public security group
  ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "Allow MySQL access from public instances"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = local.tags
}

module "back_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "back_security_group"
  description = "Security group for Backend to the Database"
  vpc_id      = module.vpc.vpc_id

  # Ingress rule to allow MySQL access from the public security group
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH access"
      cidr_blocks = "0.0.0.0/0" # String, not a list module.ec2_instance["Bastion"].private_ip
    },
    # Allow HTTPS access (port 443)
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS access"
      source_security_group_id = module.alb.security_group_id
    },
    # Allow HTTP access (port 80)
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP access"
      source_security_group_id = module.alb.security_group_id
    },
    # Allow access to port 3000 for the Node.js app
    {
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      description = "Node.js app access backend"
      cidr_blocks = "0.0.0.0/0"
    }
    
  ]

    egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"  # Allows all protocols
      description = "Allow all outbound traffic"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "Allow outbound MySQL traffic"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = local.tags
}


################################################################################
# EC2 Instances
################################################################################

resource "aws_key_pair" "user1" {
  key_name   = "user1"                      # The name of the key pair in AWS
  public_key = file("~/.ssh/user1.pub")     # Path to your local public key
}


module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  for_each = toset(["Frontend", "Backend", "Bastion"])

  name                   = "instance-${each.key}"
  ami                    = "ami-084568db4383264d4"  # Ubuntu Server 24.04 LTS (x86_64)
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.user1.key_name
  monitoring             = true
  
    # Assign different security groups
  vpc_security_group_ids = lookup({
    "Frontend" = [module.security_group.security_group_id],
    "Backend"  = [module.back_security_group.security_group_id],
    "Bastion"  = [module.security_group.security_group_id]
  }, each.key)

  # Assign each instance to a different subnet
  subnet_id = lookup({
    "Frontend" = module.vpc.public_subnets[0],
    "Backend"  = module.vpc.private_subnets[0],
    "Bastion"  = module.vpc.public_subnets[1]
  }, each.key)

  associate_public_ip_address = each.key != "Backend"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

################################################################################
# Application Load Balancer
################################################################################

module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name               = "my-alb"
  vpc_id             = module.vpc.vpc_id
  subnets            = [module.vpc.public_subnets[2], module.vpc.public_subnets[3]]
  enable_deletion_protection = false

  # Security Group
  enforce_security_group_inbound_rules_on_private_link_traffic = "on"
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = local.vpc_cidr
    }
  }

  listeners = {
    ex-http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
 
  target_groups = {
    ex-instance = {
      name_prefix      = "h1"
      protocol         = "HTTP"
      port             = 80
      target_type = "instance"
      target_id   = module.ec2_instance["Backend"].id
    }
  }

  tags = {
    Environment = "Development"
    Project     = "Example"
  }
}


/*

*/