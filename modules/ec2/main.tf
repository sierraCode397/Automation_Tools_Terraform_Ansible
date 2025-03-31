resource "aws_key_pair" "user1" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)  # Reads your local SSH key
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  for_each = toset(["Frontend", "Backend", "Bastion"])

  name                   = "instance-${each.key}"
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.user1.key_name
  monitoring             = true
  
  vpc_security_group_ids = lookup(var.security_groups, each.key, [])
  subnet_id             = lookup(var.subnets, each.key, null)

  associate_public_ip_address = each.key != "Backend"
  user_data = each.key == "Bastion" ? file("${path.module}/bastion_user_data.sh") : null

  tags = var.tags
}
