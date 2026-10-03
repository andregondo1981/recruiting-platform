output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.app.repository_url
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.utc_alb.dns_name
}

output "ecs_service_name" {
  value       = "utc-app-service"
  description = "The name of the running ECS Fargate service"
}