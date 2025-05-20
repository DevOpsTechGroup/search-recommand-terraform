# modules/aws/compute/ecs/outputs.tf
output "ecs_cluster_id" {
  description = "ECS Cluster ID 반환"
  value = {
    for key, value in aws_ecs_cluster.ecs_cluster : key => value.id
  }
}

output "ecs_cluster_name" {
  description = "ECS Cluster Name 반환"
  value = {
    for key, value in aws_ecs_cluster.ecs_cluster : key => value.name
  }
}

output "ecs_cluster_arn" {
  description = "ECS Cluster ARN 반환"
  value = {
    for key, value in aws_ecs_cluster.ecs_cluster : key => value.arn
  }
}

output "ecs_service_id" {
  description = "ECS Service ID 반환"
  value = {
    for key, value in aws_ecs_service.ecs_service : key => value.id
  }
}

output "ecs_service_name" {
  description = "ECS Service Name 반환"
  value = {
    for key, value in aws_ecs_service.ecs_service : key => value.name
  }
}
