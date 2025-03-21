#Just a VPC

# Just a VPC

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.79.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Create the VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc_Isaac"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a"]
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_nat_gateway  = false
  enable_vpn_gateway  = false
  enable_dns_hostnames = true
  enable_dns_support  = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Create a route table for the public subnet to route traffic to the Internet Gateway
resource "aws_route_table" "public_route_table" {
  vpc_id = module.vpc.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = module.vpc.igw_id  
  }
}

# -------------------------------
# Create a Security Group for SSH, HTTP, HTTPS, and TCP 8080
# -------------------------------
resource "aws_security_group" "allow_traffic" {
  name        = "allow-traffic"
  description = "Allow SSH, HTTP, HTTPS, and TCP 8080 traffic"
  vpc_id      = module.vpc.vpc_id

  # Allow SSH from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow TCP 8080 from anywhere
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "my-security-group"
  }
}


#A complete VPC

/* # Create the VPC
resource "aws_vpc" "tf_import_vpc" {
  cidr_block                  = "172.31.0.0/16"
  enable_dns_support          = true
  enable_dns_hostnames        = true
  instance_tenancy            = "default"
  assign_generated_ipv6_cidr_block = false

  # DHCP Options ID
  dhcp_options_id             = "dopt-09f6f06a3750843c1"

  tags = {
    "Name" = "TerraformVPC"
  }
}

# Create a default security group in the VPC
resource "aws_security_group" "default_sg" {
  name        = "default_sg"
  description = "Default security group for the VPC"
  vpc_id      = aws_vpc.tf_import_vpc.id

  # Add a basic inbound rule to allow SSH access (Port 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic by default
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "default_sg"
  }
}

# Create a default route table for the VPC
resource "aws_route_table" "default_route_table" {
  vpc_id = aws_vpc.tf_import_vpc.id

  # Create a default route to the internet (for public subnet setup)
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default_igw.id
  }

  tags = {
    "Name" = "default_route_table"
  }
}

# Create an internet gateway for internet access
resource "aws_internet_gateway" "default_igw" {
  vpc_id = aws_vpc.tf_import_vpc.id

  tags = {
    "Name" = "default_igw"
  }
}

# Associate the route table with the VPC's main route table
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.default_route_table.id
}

# Create a public subnet in the VPC
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.tf_import_vpc.id
  cidr_block              = "172.31.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    "Name" = "public_subnet"
  }
}
 */