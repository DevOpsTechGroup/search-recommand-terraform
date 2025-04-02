# modules/aws/compute/ecs/outputs.tf
output "container_definitions" {
  description = "ECS 작업 정의의 컨테이너 정의 JSON"
  value = {
    for key, value in data.template_file.container_definitions : key => value.rendered
  }
}

output "ecs_security_group" {
  description = "ECS 보안 그룹 정보"
  value = {
    for key, value in aws_security_group.ecs_security_group : key => value.id
  }
}