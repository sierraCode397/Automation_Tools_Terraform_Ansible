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

  security_groups = {
    default = {
      name        = "Frontend"
      description = "Security group allowing access on HTTP, HTTPS, SSH, and custom Node.js port"
      ingress = [
        {
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          description = "SSH access"
          cidr_blocks = "0.0.0.0/0"
        },
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          description = "HTTPS access"
          cidr_blocks = "0.0.0.0/0"
        },
        {
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          description = "HTTP access"
          cidr_blocks = "0.0.0.0/0"
        },
        {
          from_port   = 3030
          to_port     = 3030
          protocol    = "tcp"
          description = "Node.js app access"
          cidr_blocks = "0.0.0.0/0"
        }
      ]
      egress = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          description = "Allow all outbound traffic"
          cidr_blocks = "0.0.0.0/0"
        }
      ]
    }
    rds = {
      name        = "RDS"
      description = "Security group for RDS MySQL Database"
      ingress = [
        {
          from_port   = 3306
          to_port     = 3306
          protocol    = "tcp"
          description = "Allow MySQL access from public instances"
          cidr_blocks = "0.0.0.0/0"
        }
      ]
      egress = []  # Using default egress rules provided by the module if necessary, or you can specify an empty list.
    }
    back = {
      name        = "Backend"
      description = "Security group for Backend to the Database"
      ingress = [
        {
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          description = "SSH access"
          cidr_blocks = "0.0.0.0/0"
        },
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          description = "HTTPS access"
          cidr_blocks = "0.0.0.0/0"
        },
        {
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          description = "HTTP access"
          cidr_blocks = "0.0.0.0/0"
        },
        {
          from_port   = 3000
          to_port     = 3000
          protocol    = "tcp"
          description = "Node.js app access backend"
          cidr_blocks = "0.0.0.0/0"
        }
      ]
      egress = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
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
    }
    load = {
      name        = "LoadBalancer"  # You can customize the name if needed (e.g., "${local.name}-load")
      description = "LoadBalancer"
      ingress = [
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          description = "HTTPS access"
          cidr_blocks = "0.0.0.0/0"
        },
        {
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          description = "HTTP access"
          cidr_blocks = "0.0.0.0/0"
        },
        {
          from_port   = 3000
          to_port     = 3000
          protocol    = "tcp"
          description = "Node.js app access backend"
          cidr_blocks = "0.0.0.0/0"
        }
      ]
      egress = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          description = "Allow all outbound traffic"
          cidr_blocks = "0.0.0.0/0"
        }
      ]
    }
  }
}
