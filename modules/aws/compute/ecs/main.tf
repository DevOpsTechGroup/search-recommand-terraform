# ECS cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  for_each = {
    for key, value in var.ecs_cluster : key => value if local.create_ecs_cluster
  }

  name = "${each.value.cluster_name}-${each.value.env}" # core-search-cluster-stg

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = "${each.value.cluster_name}-${each.value.env}"
  })
}

# ECS task definition
resource "aws_ecs_task_definition" "ecs_task_definition" {
  for_each = {
    for key, value in var.ecs_task_definitions : key => value if local.create_ecs_task_definition
  }

  family                   = "${each.value.task_family}-${each.value.env}"
  cpu                      = each.value.task_total_cpu
  memory                   = each.value.task_total_memory
  network_mode             = each.value.network_mode
  requires_compatibilities = [each.value.launch_type] # EC2, FARATE

  # ECS Task Role & Task Exec Role 설정
  task_role_arn      = var.ecs_task_role_arn
  execution_role_arn = var.ecs_task_exec_role_arn

  # (기존에 생성되어 있는 Role 참조)
  # task_role_arn      = data.aws_iam_role.ecs_task_role[each.value.name].arn
  # execution_role_arn = data.aws_iam_role.ecs_task_exec_role[each.value.name].arn

  runtime_platform {
    operating_system_family = each.value.runtime_platform_oprating_system_family
    cpu_architecture        = each.value.runtime_platform_cpu_architecture
  }

  lifecycle {
    ignore_changes = [container_definitions]
    # prevent_destroy = true # 삭제 방지
  }

  # task_definitions.tpl 파일에 있는 mountPoints 이름을 volume으로 사용
  # ECS Fargate의 경우 volume 사용이 불가능하여, bind mount(host path) 사용
  volume {
    name = each.value.volume.name
  }

  # ECS 임시 휘발성 볼륨 지정
  ephemeral_storage {
    size_in_gib = each.value.ephemeral_storage
  }

  # ECS Task Definition 파일을 읽어서
  container_definitions = jsonencode(local.task_definition_container_flat[each.key])

  tags = merge(var.tags, {
    Name = "${each.value.task_family}-${each.value.env}"
  })
}

# ECS service
resource "aws_ecs_service" "ecs_service" {
  for_each = {
    for key, value in var.ecs_service : key => value if local.create_ecs_service
  }

  launch_type = each.value.launch_type
  # iam_role                          = each.value.service_role                                                      # IAM Role
  cluster                           = "${each.value.cluster_name}-${each.value.env}"                               # ECS 클러스터 이름
  name                              = "${each.value.service_name}-${each.value.env}"                               # ECS 서비스 이름
  desired_count                     = each.value.desired_count                                                     # 원하는 태스크 개수
  health_check_grace_period_seconds = each.value.health_check_grace_period_sec                                     # 헬스 체크 그레이스 기간
  task_definition                   = aws_ecs_task_definition.ecs_task_definition[each.value.task_definitions].arn # Task Definition ARN

  # 네트워크 구성 (Private Subnet 사용)
  network_configuration {
    subnets          = var.public_subnet_ids # subnet-xxxx, subnet-xxxx, subnet-xxxx
    security_groups  = [var.ecs_security_group_id[each.value.security_group_name]]
    assign_public_ip = each.value.assign_public_ip
  }

  # ALB와 연동된 Load Balancer 설정
  load_balancer {
    target_group_arn = lookup(var.alb_tg_arn, each.value.target_group_arn, null)
    container_name   = "${each.value.container_name}-${each.value.env}"
    container_port   = each.value.container_port
  }

  # 배포 회로 차단기 및 롤백
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # 배포 컨트롤러 설정
  deployment_controller {
    type = each.value.deployment_controller
  }

  lifecycle {
    # prevent_destroy = true # Terraform 리소스 삭제 방지
    create_before_destroy = true # 리소스 삭제 되기 전 생성 후 삭제 진행
  }

  # ECS Service는 Cluster, TD, 보안그룹이 생성된 이후에 생성 되어야 함
  depends_on = [
    aws_ecs_cluster.ecs_cluster,
    aws_ecs_task_definition.ecs_task_definition
  ]

  tags = merge(var.tags, {
    Name = "${each.value.service_name}-${each.value.env}"
  })
}

# ECS autoscaling appautoscaling target
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target.html
# arn:aws:ecs:ap-northeast-2:7xxxxxxxxxx:service/search-xxxx-cluster-prod/search-xxxx-service-nlb-prod
resource "aws_appautoscaling_target" "ecs_target" {
  for_each = {
    for key, value in var.ecs_appautoscaling_target : key => value if local.create_appautoscaling_target
  }

  min_capacity       = each.value.min_capacity       # 최소 Task 2개가 항상 실행되도록 설정
  max_capacity       = each.value.max_capacity       # 최대 Task 6개까지 증가 할 수 있도록 설정
  resource_id        = each.value.resource_id        # AG를 적용할 대상 리소스 지정, 여기서는 ECS 서비스 ARN 형식의 일부 기재
  scalable_dimension = each.value.scalable_dimension # 조정할 수 있는 AWS 리소스의 특정 속성을 지정하는 필드
  service_namespace  = each.value.service_namespace  # ECS namespace 지정

  depends_on = [
    aws_ecs_service.ecs_service
  ]
}

# ECS autoscaling scale out policy
resource "aws_appautoscaling_policy" "ecs_policy_scale_out" {
  for_each = {
    for key, value in var.ecs_appautoscaling_target_policy : key => value if local.create_appautoscaling_policy
  }

  name               = each.value.scale_out.name                                         # AutoScaling 정책 이름
  policy_type        = each.value.scale_out.policy_type                                  # AutoScaling 정책 타입(How to scale out?)
  resource_id        = aws_appautoscaling_target.ecs_target[each.key].resource_id        # AutoScaling이 적용될 ECS 서비스 ID
  scalable_dimension = aws_appautoscaling_target.ecs_target[each.key].scalable_dimension # AutoScaling이 적용될 리소스의 스케일링 속성(ecs:service:DesiredCount)
  service_namespace  = aws_appautoscaling_target.ecs_target[each.key].service_namespace  # AWS 서비스 네임스페이스 (ecs, dynamodb, sagemaker 등)

  step_scaling_policy_configuration {
    adjustment_type         = each.value.scale_out.step_scaling_policy_conf.adjustment_type         # AutoScaling 조정 방식(PercentChangeInCapacity)
    cooldown                = each.value.scale_out.step_scaling_policy_conf.cooldown                # Auto Scaling 이벤트 후 다음 이벤트까지 대기 시간 (초)
    metric_aggregation_type = each.value.scale_out.step_scaling_policy_conf.metric_aggregation_type # 측정 지표의 집계 방식 (Average 등)

    dynamic "step_adjustment" {
      for_each = each.value.scale_out.step_scaling_policy_conf.step_adjustment

      content {
        metric_interval_lower_bound = step_adjustment.value.metric_interval_lower_bound
        metric_interval_upper_bound = step_adjustment.value.metric_interval_upper_bound
        scaling_adjustment          = step_adjustment.value.scaling_adjustment
      }
    }
  }
}

# ECS scaleout policy alarm
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_scale_out_alert" {
  for_each = {
    for key, value in var.ecs_cpu_scale_out_alert : key => value if local.create_cloudwatch_metric_alarm
  }

  // TODO: ECS ScaleOut CPU 알람 생성 및 설정
  alarm_name          = each.value.alarm_name          # Cloudwatch 알람 이름
  comparison_operator = each.value.comparison_operator # 메트릭 값과 임계값 비교할 때 사용할 연산자 지정(GreaterThanThreshold, LessThanThreshold)
  evaluation_periods  = each.value.evaluation_periods  # 평가 기간(1)
  metric_name         = each.value.metric_name         # 메트릭 이름 지정 -> CPUUtilization
  namespace           = each.value.namespace           # 메트릭이 속한 네임스페이스 지정
  period              = each.value.period              # 메트릭 데이터 집계 간격(초) 지정
  statistic           = each.value.statistic           # 메트릭 통계 방식 지정(Average, Sum)
  threshold           = each.value.threshold           # 알람 발동을 위한 임계값 지정

  dimensions = {
    ClusterName = aws_ecs_cluster.ecs_cluster[each.value.dimensions.cluster_name].name
    ServiceName = aws_ecs_service.ecs_service[each.value.dimensions.service_name].name
  }

  # TODO: Slack 있으면 SNS 사용해서 연동 해주어도 될 듯
  # 알람 발동 시 어떤 정책을 사용할지 연결
  alarm_actions = [
    aws_appautoscaling_policy.ecs_policy_scale_out[each.key].arn
  ]

  tags = merge(var.tags, {
    Name = "${each.value.alarm_name}-${each.value.env}"
  })
}
