# 1. ECR Repository for Container Images
resource "aws_ecr_repository" "app" {
  name                 = "utc-recruiting-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "utc-ecr-repository"
  }
}

# 2. ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "utc-application-cluster"

  tags = {
    Name = "utc-application-cluster"
  }
}

# 3. CloudWatch Log Group for Container Logs
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/utc-app-task"
  retention_in_days = 7

  tags = {
    Name = "utc-ecs-log-group"
  }
}

# 4. ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "utc-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "webapp"
      image     = "${aws_ecr_repository.app.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "utc-app-task-definition"
  }
}

# 5. ECS Service (Running tasks in private subnets behind the ALB)
resource "aws_ecs_service" "app" {
  name                 = "utc-app-service"
  cluster              = aws_ecs_cluster.main.id
  task_definition      = aws_ecs_task_definition.app.arn
  desired_count        = 2
  launch_type          = "FARGATE"
  force_new_deployment = true

  network_configuration {
    subnets          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    security_groups  = [aws_security_group.app_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.utc_tg.arn
    container_name   = "webapp"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.http]

  tags = {
    Name = "utc-app-service"
  }
}