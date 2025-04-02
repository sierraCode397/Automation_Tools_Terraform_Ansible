provider "aws" {
  region = local.region
}

terraform {
  backend "s3" {
    bucket = "terraform-state-final-task"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_availability_zones" "available" {}



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
  source = "./modules/rds"  # Path to the rds module

  name                     = local.name
  engine                   = "mysql"
  engine_version           = "8.0"
  instance_class           = "db.t3.micro"
  allocated_storage        = 20
  max_allocated_storage    = 100
  db_name                  = "completeMysql"
  username                 = jsondecode(aws_secretsmanager_secret_version.rds_password_version.secret_string).username
  password                 = jsondecode(aws_secretsmanager_secret_version.rds_password_version.secret_string).password
  db_subnet_group_name     = module.vpc.database_subnet_group
  vpc_security_group_ids   = [module.security_groups["RDS"].security_group_id]
  tags                     = local.tags
  db_instance_tags         = {
    "Sensitive" = "high"
  }
  db_parameter_group_tags  = {}
  cloudwatch_log_group_tags = {}   
  db_option_group_tags = {}
  db_subnet_group_tags = {}
  storage_encrypted        = false
  kms_key_id               = null
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

  enable_nat_gateway = true
  single_nat_gateway = true
  one_nat_gateway_per_az = false

  tags = local.tags
}

################################################################################
# Security Groups
################################################################################

module "security_groups" {
  for_each = local.security_groups

  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = each.value.name
  description = each.value.description
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = each.value.ingress
  egress_with_cidr_blocks  = each.value.egress

  tags = local.tags
}



################################################################################
# EC2 Instances
################################################################################

module "ec2" {
  source = "./modules/ec2"

  key_name        = "user1"
  public_key_path = "~/.ssh/user1.pub"
  ami_id          = "ami-084568db4383264d4"
  instance_type   = "t2.micro"

  security_groups = {
    "Frontend" = [module.security_groups["Frontend"].security_group_id]
    "Backend"  = [module.security_groups["Backend"].security_group_id]
    "Bastion"  = [module.security_groups["Bastion"].security_group_id]
  }

  subnets = {
    "Frontend" = module.vpc.public_subnets[0]
    "Backend"  = module.vpc.private_subnets[0]
    "Bastion"  = module.vpc.public_subnets[1]
  }
}

################################################################################
# Application Load Balancer
################################################################################

module "load_balancer" {
  source = "./modules/load_balancer"  # Path to the load balancer module

  name                     = "my-alb"
  security_groups          = [module.security_groups["LoadBalancer"].security_group_id]
  subnets                  = [module.vpc.public_subnets[2], module.vpc.public_subnets[3]]
  enable_deletion_protection = false
  tags                     = {
    Name = "whiz-alb"
  }

  target_group_name        = "my-target-group"
  target_group_port        = 3000
  target_group_protocol    = "HTTP"
  vpc_id                   = module.vpc.vpc_id
  listener_port            = 80
  listener_protocol        = "HTTP"
  target_id                = module.ec2_instance["Backend"].id
}
