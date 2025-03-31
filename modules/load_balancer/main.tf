# Create the Load Balancer
resource "aws_lb" "application-lb" {
  name                     = var.name
  internal                 = false
  ip_address_type          = "ipv4"
  load_balancer_type       = "application"
  security_groups          = var.security_groups
  subnets                  = var.subnets
  enable_deletion_protection = var.enable_deletion_protection
  enable_cross_zone_load_balancing = true

  tags = var.tags
}

# Create a Target Group
resource "aws_lb_target_group" "target_group" {
  name     = var.target_group_name
  port     = var.target_group_port
  protocol = var.target_group_protocol
  vpc_id   = var.vpc_id
  target_type = "instance"
}

# Create an HTTP Listener for the Load Balancer
resource "aws_lb_listener" "alb-listener" {
  load_balancer_arn = aws_lb.application-lb.arn
  port              = var.listener_port
  protocol          = var.listener_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

# Attachment to EC2 Instances
resource "aws_lb_target_group_attachment" "ec2_attach" {
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = var.target_id
  port             = var.target_group_port
}