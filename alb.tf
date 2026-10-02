# 1. Application Load Balancer (Spanning public subnets for Multi-AZ redundancy)
resource "aws_lb" "utc_alb" {
  name               = "utc-application-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  enable_deletion_protection = false

  tags = {
    Name = "utc-application-alb"
  }
}

# 2. Target Group (Configured for IP target type required by ECS Fargate)
resource "aws_lb_target_group" "utc_tg" {
  name        = "utc-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "utc-target-group"
  }
}

# 3. ALB HTTP Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.utc_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.utc_tg.arn
  }
}