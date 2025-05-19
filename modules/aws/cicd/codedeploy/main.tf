# https://medium.com/@ywg/blue-green-deployment-on-aws-ecs-with-terraform-7dfd67502b5b
# https://registry.terraform.io/providers/hashicorp/aws/3.74.3/docs/resources/codedeploy_app#ecs-application
# CodeDeploy Application 생성
resource "aws_codedeploy_app" "codedeploy_app" {
  for_each = var.codedeploy_app

  compute_platform = each.value.compute_platform # Compute 플랫폼 지정 (ECS, Lambda, Server)
  name             = each.value.name             # CodeDeploy Application명

  tags = merge(var.tags, {
    Name = "${each.value.name}-${each.value.env}"
  })
}

# https://registry.terraform.io/providers/hashicorp/aws/3.74.3/docs/resources/codedeploy_deployment_group#blue-green-deployments-with-ecs
# CodeDeploy Application 배포 그룹 생성
resource "aws_codedeploy_deployment_group" "codedeploy_deployment_group" {
  for_each = var.codedeploy_deployment_group

  app_name               = aws_codedeploy_app.codedeploy_app[each.value.app_name].name # CodeDeploy Application명 지정
  deployment_group_name  = "${each.value.deployment_group_name}-${each.value.env}"     # 배포 그룹명
  deployment_config_name = each.value.deployment_config_name                           # 배포 그룹 방식 (CodeDeployDefault.ECSAllAtOnce)
  service_role_arn       = var.service_role_arn

  # 배포 실패 시 자동 롤백 설정
  auto_rollback_configuration {
    enabled = each.value.auto_rollback_configuration.enabled
    events  = [each.value.auto_rollback_configuration.events]
  }

  # Blue/Green 배포 전략 관련 설정
  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout    = each.value.blue_green_deployment_config.deployment_ready_option.action_on_timeout
      wait_time_in_minutes = each.value.blue_green_deployment_config.deployment_ready_option.wait_time_in_minutes
    }

    terminate_blue_instances_on_deployment_success {
      action                           = each.value.blue_green_deployment_config.terminate_blue_instances_on_deployment_success.action
      termination_wait_time_in_minutes = each.value.blue_green_deployment_config.terminate_blue_instances_on_deployment_success.termination_wait_time_in_minutes
    }
  }

  # Blue/Green 배포 방식 설정
  deployment_style {
    deployment_type   = each.value.deployment_style.deployment_type
    deployment_option = each.value.deployment_style.deployment_option
  }

  # 해당 배포 그룹에 연결 된 ECS 정보
  ecs_service {
    cluster_name = "${each.value.ecs_service.cluster_name}-${each.value.env}"
    service_name = "${each.value.ecs_service.service_name}-${each.value.env}"
  }

  # 로드 밸런서 및 타겟 그룹 설정
  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route { # 실제 트래픽이 전달 될 ALB 리스너 ARN
        listener_arns = [var.alb_listener_arn[each.value.load_balancer_info.target_group_pair_info.prod_traffic_route.listener_arns]]
      }

      test_traffic_route { # 테스트 트래픽이 전달 될 ALB 리스너 ARN
        listener_arns = [var.alb_listener_arn[each.value.load_balancer_info.target_group_pair_info.test_traffic_route.listener_arns]]
      }

      # Blue/Green 타겟그룹 연결
      dynamic "target_group" {
        for_each = each.value.load_balancer_info.target_group_pair_info.target_group
        content {
          name = "${target_group.value.name}-${each.value.env}"
        }
      }
    }
  }

  tags = merge(var.tags, {
    Name = "${each.value.deployment_group_name}-${each.value.env}"
  })
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_deployment_config
# CodeDeploy Application의 배포 구성 생성
resource "aws_codedeploy_deployment_config" "codedeploy_deployment_config" {
  for_each = var.codedeploy_deployment_config

  deployment_config_name = each.value.deployment_config_name # CodeDeploy에서 사용할 배포 구성 이름
  compute_platform       = each.value.compute_platform       # 배포 대상 플랫폼(ECS, Lambda, Server 중 하나)

  traffic_routing_config {
    type = each.value.traffic_routing_config.type # 트래픽 라우팅 전략(BLUE_GREEN)

    # 배포 시 Canary 방식으로 트래픽을 점진적으로 전환하기 위한 설정
    time_based_canary {
      interval   = each.value.traffic_routing_config.time_based_canary.interval   # 트래픽 전환 간격 (분)
      percentage = each.value.traffic_routing_config.time_based_canary.percentage # 초기 전환 비율 (%)
    }
  }
}
