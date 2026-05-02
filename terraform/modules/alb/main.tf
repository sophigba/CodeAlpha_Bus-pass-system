# terraform/modules/alb/main.tf

resource "aws_lb" "buspass_alb" {
  name               = "buspass-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = [var.public_subnet_a_id, var.public_subnet_b_id]
  tags               = { Name = "BusPass-ALB" }
}

resource "aws_lb_target_group" "buspass_tg" {
  name     = "buspass-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    interval            = 30
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.buspass_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.buspass_tg.arn
  }
}

# Attach ASG to ALB target group
resource "aws_autoscaling_attachment" "asg_alb" {
  autoscaling_group_name = var.asg_name
  lb_target_group_arn    = aws_lb_target_group.buspass_tg.arn
}