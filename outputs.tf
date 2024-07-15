output "ecs_cluster_name" {
  value       = aws_ecs_cluster.main.name
  description = "Name of the ECS cluster"
}

output "ecs_service_name" {
  value       = aws_ecs_service.flask_service.name
  description = "Name of the ECS service"
}

output "ecs_task_definition" {
  value       = aws_ecs_task_definition.flask_task.family
  description = "Family name of the ECS task definition"
}

output "instance_public_ip" {
  value       = aws_instance.example.public_ip
  description = "Public IP address of the EC2 instance"
}

output "load_balancer_dns" {
  value       = aws_lb.flask_lb_new.dns_name
  description = "DNS name of the load balancer"
}
