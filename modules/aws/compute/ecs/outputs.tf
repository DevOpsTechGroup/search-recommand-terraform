# modules/aws/compute/ecs/outputs.tf
output "container_definitions" {
  description = "ECS 작업 정의의 컨테이너 정의 JSON"
  value = {
    for key, value in data.template_file.container_definitions : key => value.rendered
  }
}
