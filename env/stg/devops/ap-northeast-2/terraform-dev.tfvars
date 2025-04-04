########################################
# 프로젝트 기본 설정
########################################
project_name = "search-xxxx"
aws_region   = "ap-northeast-2"

availability_zones = [
  "ap-northeast-2a",
  "ap-northeast-2b",
  "ap-northeast-2c",
]
aws_account = "8xxxxxxxxxxx"
env         = "stg"

########################################
# 네트워크 설정
########################################
# IP 대역
# 10.0.0.0 - 10.255.255.255		-> 		16,777,216
# 172.16.0.0 - 172.31.255.255		-> 		1,048,576
# 192.168.0.0 - 192.168.255.255	->		65,536
# VPC ID - 외부 data 변수를 통해 받음, 초기에는 빈값으로 셋팅
vpc_id = ""

# VPC CIDR 대역 지정 - VPC CIDR는 개발환경에 적합한 크기로 설정
vpc_cidr = "172.x.x.x/x"

# 각 가용영역마다 하나의 public/private 서브넷 -> 가용 영역은 현재 2개
# 퍼블릭 서브넷 지정 -> 서브넷 당 256개 IP 사용 가능(5개는 빼야함)
# /24 -> 앞의 3개의 IP가 네트워크 주소, 나머지 8비트가 호스트 비트
public_subnets_cidr = [
  "172.21.x.x/24",
  "172.21.x.x/24",
  "172.21.x.x/24"
]

# 프라이빗 서브넷 지정
private_subnets_cidr = [
  "172.21.x.x/24",
  "172.21.x.x/24",
  "172.21.x.x/24",
]

# 퍼블릭 서브넷 ID 지정
public_subnet_ids = []

# 프라이빗 서브넷 ID 지정
private_subnet_ids = []

# DNS Hostname 사용 옵션, 기본 false(VPC 내 리소스가 AWS DNS 주소 사용 가능)
# DNS 기능 자체를 켤지 말지 정하는 옵션, 키는 경우 VPC에서 DNS 기능 사용 가능
# 활성화 : DNS -> IP / IP -> DNS
# 비활성화 : IP로만 통신 가능
enable_dns_support = true

# DNS 이름을 만들지 말지 정하는 옵션, 이것도 켜야 실제 VPC 내의 리소스들이 DNS로 통신이 가능할 듯
enable_dns_hostnames = true

########################################
# 로드밸런서 설정
########################################
alb = {
  search-xxxx-alb = {
    create_yn                        = true
    name                             = "search-xxxx-alb"
    internal                         = false
    load_balancer_type               = "application"
    enable_deletion_protection       = false # 생성하고 난 후에 true로 변경
    enable_cross_zone_load_balancing = true
    idle_timeout                     = 300
    security_group_name              = "search-xxxx-alb-sg"
    env                              = "stg"
  }
}

# ALB 보안그룹 생성
alb_security_group = {
  search-xxxx-alb-sg = {
    create_yn           = true
    security_group_name = "search-xxxx-alb-sg"
    description         = "search-xxxx alb security group"
    env                 = "stg"
  }
}

# ALB Listencer 생성
alb_listener = {
  alb-http-listener = {
    create_yn         = true
    name              = "alb-http-listener"
    port              = 80
    protocol          = "HTTP"
    load_balancer_arn = "search-xxxx-alb" # 연결할 ALB 이름 지정
    default_action = {                    # TODO: 고정 응답 값 반환하도록 수정
      type = "fixed-response"             # forward, redirect(다른 URL 전환), fixed-response(고정 응답값)
      # target_group_arn = "opensearch-alb-tg"
      fixed_response = {
        content_type = "text/plain"
        message_body = "Fixed response content"
        status_code  = "200"
      }
    }
    env = "stg"
  }
}

# ALB Listener Rule 생성
alb_listener_rule = {
  opensearch-alb-http-listener-rule = {
    create_yn         = true
    type              = "forward"
    path              = ["/URL"]
    alb_listener_name = "alb-http-listener"
    target_group_name = "opensearch-alb-tg"
    priority          = 1
  },
  elasticsearch-alb-http-listener-rule = {
    create_yn         = true
    type              = "forward"
    path              = ["/URL"]
    alb_listener_name = "alb-http-listener"
    target_group_name = "elasticsearch-alb-tg"
    priority          = 2
  }
}

# ALB Target Group 생성
target_group = {
  opensearch-alb-tg = {
    create_yn   = true
    name        = "opensearch-alb-tg"
    port        = 10091
    elb_type    = "ALB"
    protocol    = "HTTP" # HTTP(ALB) or TCP(NLB)
    target_type = "ip"   # FARGATE는 IP로 지정해야 함, 동적으로 IP(ENI) 할당됨
    env         = "stg"
    health_check = {
      path                = "/health-check"
      enabled             = true
      healthy_threshold   = 3
      interval            = 30
      port                = 10091
      protocol            = "HTTP"
      timeout             = 15
      unhealthy_threshold = 5
      internal            = false
    }
  },
  elasticsearch-alb-tg = {
    create_yn   = true
    name        = "elasticsearch-alb-tg"
    port        = 10092
    elb_type    = "ALB"
    protocol    = "HTTP" # HTTP(ALB) or TCP(NLB)
    target_type = "ip"   # FARGATE는 IP로 지정해야 함, 동적으로 IP(ENI) 할당됨
    env         = "stg"
    health_check = {
      path                = "/health-check"
      enabled             = true
      healthy_threshold   = 3
      interval            = 30
      port                = 10092
      protocol            = "HTTP"
      timeout             = 15
      unhealthy_threshold = 5
      internal            = false
    }
  }
}

alb_security_group_id = {}

########################################
# ECR 설정
########################################
# ECR 리포지토리 생성
ecr_repository = {
  opensearch-api = {
    create_yn                = true
    ecr_repository_name      = "opensearch-api" # 리포지토리명
    env                      = "stg"            # ECR 개발환경
    ecr_image_tag_mutability = "IMMUTABLE"      # image 버전 고유하게 관리할지 여부
    ecr_scan_on_push         = false            # PUSH Scan 여부
    ecr_force_delete         = false
  },
  elasticsearch-api = {
    create_yn                = true
    ecr_repository_name      = "elasticsearch-api" # 리포지토리명
    env                      = "stg"               # ECR 개발환경
    ecr_image_tag_mutability = "IMMUTABLE"         # image 버전 고유하게 관리할지 여부
    ecr_scan_on_push         = false               # PUSH Scan 여부
    ecr_force_delete         = false
  }
}

########################################
# IAM 설정
########################################
# 사용자가 생성하는 역할(Role)
iam_custom_role = {
  ecs-task-role = {
    create_yn = true
    name      = "ecs-task-role"
    version   = "2012-10-17"
    arn       = ""
    statement = {
      Sid    = "ECSTaskRole"
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }
    env = "stg"
  },
  ecs-task-exec-role = {
    create_yn = true
    name      = "ecs-task-exec-role"
    version   = "2012-10-17"
    arn       = ""
    statement = {
      Sid    = "ECSTaskExecRole"
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }
    env = "stg"
  },
  ecs-auto-scaling-role = {
    create_yn = true
    name      = "ecs-auto-scaling-role"
    version   = "2012-10-17"
    arn       = ""
    statement = {
      Sid    = "ECSAutoScalingRole"
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "application-autoscaling.amazonaws.com"
      }
    }
    env = "stg"
  }
}

# 사용자가 생성하는 정책(Policy)
iam_custom_policy = {
  ecs-task-role-policy = {
    create_yn   = true
    name        = "ecs-task-role-policy"
    description = "Policy For ECS Task Role"
    version     = "2012-10-17"
    statement = {
      Sid = "ECSTaskRolePolicy"
      Action = [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject"
      ]
      Effect = "Allow"
      Resource = [
        "*"
      ]
    }
    env = "stg"
  },
  ecs-task-exec-role-policy = {
    create_yn   = true
    name        = "ecs-task-exec-role-policy"
    description = "Policy For ECS Task Execution Role"
    version     = "2012-10-17"
    statement = {
      Sid = "ECSTaskExecRolePolicy"
      Action = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:GetRepositoryPolicy",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Effect = "Allow"
      Resource = [
        "*"
      ] # TODO: 범위 좁혀야함
    }
    env = "stg"
  }
}

/*
  기존 AWS에서 제공되는 정책 사용(Policy) - data "aws_iam_policy" "existing_policy" { }
  아래 변수의 경우 Policy를 사용하기는 하는데, 기존 AWS Managed Policy를 사용하는 경우 사용하는 변수
*/
iam_managed_policy = {
  ecs-auto-scaling-role-policy = {
    create_yn = true
    name      = "AmazonEC2ContainerServiceAutoscaleRole"
    arn       = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
    env       = "stg"
  }
}

/*
  Role, Policy 생성 후 Role에 Policy를 연동할 때 사용하는 변수로,
  policy_type의 경우 아래와 같이 구분해서 사용한다.

  role_name, policy_name은 iam_custom_role, iam_custom_policy, iam_managed_policy,
  Map 변수의 key 이름과 반드시 동일하게 설정 해주어야 한다.

  - custom: 사용자가 생성한 policy
  - managed: AWS에서 제공하는 managed policy
*/
iam_policy_attachment = {
  ecs-task-role-attachment = {
    create_yn   = true
    role_name   = "ecs-task-role"
    policy_name = "ecs-task-role-policy"
    policy_type = "custom"
  },
  ecs-task-exec-role = {
    create_yn   = true
    role_name   = "ecs-task-exec-role"
    policy_name = "ecs-task-exec-role-policy"
    policy_type = "custom"
  },
  ecs-auto-scaling-role = {
    create_yn   = true
    role_name   = "ecs-auto-scaling-role"
    policy_name = "ecs-auto-scaling-role-policy"
    policy_type = "managed"
  }
}

########################################
# ECS 클러스터 설정
########################################
# ECS 클러스터 생성
ecs_cluster = {
  search-xxxx-ecs-cluster = {
    create_yn    = true
    cluster_name = "search-xxxx-ecs-cluster"
    env          = "stg"
  }
}

# ECS Security Group 
ecs_security_group = {
  opensearch-api-sg = {
    create_yn           = true
    security_group_name = "opensearch-api-sg"
    description         = "opensearch ecs security group"
    env                 = "stg"
  },
  elasticsearch-api-sg = {
    create_yn           = true
    security_group_name = "elasticsearch-api-sg"
    description         = "elasticsearch ecs security group"
    env                 = "stg"
  }
}

# ECS IAM Role
ecs_task_role               = "ecs_task_role"
ecs_task_role_policy        = "ecs_task_role_policy"
ecs_task_exec_role          = "ecs_task_exec_role"
ecs_task_exec_role_policy   = "ecs_task_exec_role_policy"
ecs_auto_scaling_role       = "ecs_auto_scaling_role"
ecs_auto_scaling_policy_arn = "AmazonEC2ContainerServiceAutoscaleRole" # 기존에 생성되어 있는 정책을 참조

# ECS Container Image 버전
ecs_container_image_version = "1.0.0"

# embedding

# ECS Task Definitions 생성
# TODO: containers.env 추가? + image_version 어떻게 받을지?
ecs_task_definitions = {
  opensearch-api-td = {
    create_yn                               = true
    name                                    = "opensearch-api-td"
    task_role                               = "ecs_task_role"
    task_exec_role                          = "ecs_task_exec_role"
    network_mode                            = "awsvpc"
    launch_type                             = "FARGATE"
    task_total_cpu                          = 1024 # ECS Task Total CPU
    task_total_memory                       = 2048 # ECS Task Total Mem
    runtime_platform_oprating_system_family = "LINUX"
    runtime_platform_cpu_architecture       = "X86_64"
    task_family                             = "opensearch-api-td"
    cpu                                     = 1024
    memory                                  = 2048
    env                                     = "stg"
    ephemeral_storage                       = 21
    containers = [
      {
        name      = "opensearch-api"
        image     = "8xxxxxxxxxxx.dkr.ecr.ap-northeast-2.amazonaws.com/opensearch-api"
        version   = "1.0.1" # container image version은 ecs_container_image_version 변수 사용
        cpu       = 512     # container cpu
        memory    = 1024    # container mem
        port      = 10091
        essential = true
        env_variables = {
          "TZ"                     = "Asia/Seoul"
          "SPRING_PROFILES_ACTIVE" = "stg"
        }
        mount_points = []
        health_check = {
          command  = "curl --fail http://127.0.0.1:10091/health-check || exit 1"
          interval = 30
          timeout  = 10
          retries  = 3
        }
        env = "stg"
      }
    ]
  },
  elasticsearch-api-td = {
    create_yn                               = true
    name                                    = "elasticsearch-api-td"
    task_role                               = "ecs_task_role"
    task_exec_role                          = "ecs_task_exec_role"
    network_mode                            = "awsvpc"
    launch_type                             = "FARGATE"
    task_total_cpu                          = 1024 # ECS Task Total CPU
    task_total_memory                       = 2048 # ECS Task Total Mem
    runtime_platform_oprating_system_family = "LINUX"
    runtime_platform_cpu_architecture       = "X86_64"
    task_family                             = "elasticsearch-api-td"
    cpu                                     = 1024
    memory                                  = 2048
    env                                     = "stg"
    ephemeral_storage                       = 21
    containers = [
      {
        name      = "elasticsearch-api"
        image     = "8xxxxxxxxxxx.dkr.ecr.ap-northeast-2.amazonaws.com/elasticsearch-api"
        version   = "1.0.0" # container image version은 ecs_container_image_version 변수 사용
        cpu       = 512     # container cpu
        memory    = 1024    # container mem
        port      = 10092
        essential = true
        env_variables = {
          "TZ"                     = "Asia/Seoul"
          "SPRING_PROFILES_ACTIVE" = "stg"
        }
        mount_points = []
        health_check = {
          command  = "curl --fail http://127.0.0.1:10092/health-check || exit 1"
          interval = 30
          timeout  = 10
          retries  = 3
        }
        env = "stg"
      }
    ]
  },
}

# ECS 서비스 생성
ecs_service = {
  opensearch-ecs-service = {
    create_yn                     = false
    launch_type                   = "FARGATE"                 # ECS Launch Type
    service_role                  = "AWSServiceRoleForECS"    # ECS Service Role
    deployment_controller         = "ECS"                     # ECS Deployment Controller (ECS | CODE_DEPLOY | EXTERNAL)
    cluster_name                  = "search-xxxx-ecs-cluster" # ECS Cluster명
    service_name                  = "opensearch-ecs-service"  # 서비스 이름
    desired_count                 = 1                         # Task 개수
    container_name                = "opensearch-api"          # 컨테이너 이름
    container_port                = 10091                     # 컨테이너 포트
    task_definitions              = "opensearch-api-td"       # 테스크 지정
    env                           = "stg"                     # ECS Service 환경변수
    health_check_grace_period_sec = 250                       # 헬스 체크 그레이스 기간
    assign_public_ip              = false                     # 우선 public zone에 구성
    target_group_arn              = "opensearch-alb-tg"       # 연결되어야 하는 Target Group 지정
    security_group_name           = "opensearch-api-sg"       # 보안그룹 이름
  },
  elasticsearch-ecs-service = {
    create_yn                     = false
    launch_type                   = "FARGATE"                   # ECS Launch Type
    service_role                  = "AWSServiceRoleForECS"      # ECS Service Role
    deployment_controller         = "ECS"                       # ECS Deployment Controller (ECS | CODE_DEPLOY | EXTERNAL)
    cluster_name                  = "search-xxxx-ecs-cluster"   # ECS Cluster명
    service_name                  = "elasticsearch-ecs-service" # 서비스 이름
    desired_count                 = 1                           # Task 개수
    container_name                = "elasticsearch-api"         # 컨테이너 이름
    container_port                = 10092                       # 컨테이너 포트
    task_definitions              = "elasticsearch-api-td"      # 테스크 지정
    env                           = "stg"                       # ECS Service 환경변수
    health_check_grace_period_sec = 250                         # 헬스 체크 그레이스 기간
    assign_public_ip              = false                       # 우선 public zone에 구성
    target_group_arn              = "elasticsearch-alb-tg"      # 연결되어야 하는 Target Group 지정
    security_group_name           = "elasticsearch-api-sg"      # 보안그룹 이름
  },
}

# ECS Autoscaling
ecs_appautoscaling_target = {
  opensearch-service = {
    create_yn          = false
    min_capacity       = 2                                                            # 최소 Task 2개가 항상 실행되도록 설정
    max_capacity       = 6                                                            # 최대 Task 6개까지 증가 할 수 있도록 설정
    resource_id        = "service/search-xxxx-ecs-cluster-stg/opensearch-service-stg" # TODO: 하드코딩된 부분 수정 -> AG를 적용할 대상 리소스 지정, 여기서는 ECS 서비스 ARN 형식의 일부 기재
    scalable_dimension = "ecs:service:DesiredCount"                                   # 조정할 수 있는 AWS 리소스의 특정 속성을 지정하는 필드
    service_namespace  = "ecs"
    cluster_name       = "search-xxxx-ecs-cluster" # ECS 클러스터명 지정
    service_name       = "opensearch-ecs-service"  # ECS 서비스명 지정
  },
}

# ECS Autoscaling 정책
ecs_appautoscaling_target_policy = {
  opensearch-ecs-service = {
    create_yn = false
    scale_out = {
      name        = "ECSOpenSearchScaleOutPolicy" # 스케일 아웃 정책명
      policy_type = "StepScaling"                 # 정책 타입
      step_scaling_policy_conf = {
        adjustment_type         = "ChangeInCapacity" # 조정 방식 (퍼센트 증가: PercentChangeInCapacity, 개수: ChangeInCapacity)  
        cooldown                = 60                 # Autoscaling 이벤트 후 다음 이벤트까지 대기 시간(60초)
        metric_aggregation_type = "Average"          # 측정 지표의 집계 방식 (AVG: 평균)
        step_adjustment = {
          # Threshold 30 -> CPU 30 - 40% 스케일링
          between_than_10_and_20 = {
            metric_interval_lower_bound = 0  # 트리거 조건의 최소 임계값(0%)
            metric_interval_upper_bound = 10 # 트리거 조건의 최대 임계값(10%)
            scaling_adjustment          = 1  # 조정 비율 (50% 비율로 ECS Task 증가 or 개수도 지정 가능)
          },
          # Threshold 30 -> CPU 40 - 50% 스케일링
          between_than_20_and_30 = {
            metric_interval_lower_bound = 10
            metric_interval_upper_bound = 20
            scaling_adjustment          = 2
          },
          # Threshold 30 -> CPU 50 - n 스케일링
          between_than_30_and_40 = {
            metric_interval_lower_bound = 20
            scaling_adjustment          = 3 # 3개의 Task 증설
          },
        }
      }
    },
  }
}

# ECS Autoscaling Cloudwatch policy
ecs_cpu_scale_out_alert = {
  opensearch-ecs-service = {
    create_yn           = false
    alarm_name          = "ECSOpenSearchScaleOutAlarm"
    comparison_operator = "GreaterThanOrEqualToThreshold" # 메트릭이 임계값보다 크거나 같으면 발동
    evaluation_periods  = "1"                             # 평가 주기는 1번 -> 1번만 조건에 맞아도 이벤트 발생
    metric_name         = "CPUUtilization"                # 메트릭 이름은 ECS의 CPU 사용률
    namespace           = "AWS/ECS"                       # 메트릭이 속한 네임스페이스
    period              = "60"                            # 60초마다 평가 
    statistic           = "Average"                       # 집계 방식은 평균으로
    threshold           = "30"                            # 30부터 스케일링 진행
    dimensions = {
      cluster_name = "search-xxxx-ecs-cluster"
      service_name = "opensearch-ecs-service"
    }
    env = "stg"
  }
}

ecs_security_group_id = {}

########################################
# EC2 설정
########################################
# EC2 보안그룹 생성
ec2_security_group = {
  opensearch-sg = {
    create_yn           = true
    security_group_name = "opensearch-sg"
    description         = "search-xxxx vector opensearch ec2"
    env                 = "stg"
  },
  elasticsearch-sg = {
    create_yn           = true
    security_group_name = "elasticsearch-sg"
    description         = "search-xxxx elasticsearch ec2"
    env                 = "stg"
  }
}

# EC2 보안그룹 인바운드 설정
ec2_security_group_ingress_rules = {
  opensearch-sg-ingress-rule = [
    {
      create_yn           = true
      security_group_name = "opensearch-sg" # 참조하는 보안그룹 이름을 넣어야 each.key로 구분 가능
      type                = "ingress"
      description         = "opensearch ssh security group inbound"
      from_port           = 22
      to_port             = 22
      protocol            = "tcp"
      cidr_ipv4 = [
        "172.x.x.x/x",
        "220.75.180.0/24"
      ]
      source_security_group_id = null
      env                      = "stg"
    },
    {
      create_yn           = true
      security_group_name = "opensearch-sg" # 참조하는 보안그룹 이름을 넣어야 each.key로 구분 가능
      type                = "ingress"
      description         = "opensearch es security group inbound"
      from_port           = 9200
      to_port             = 9200
      protocol            = "tcp"
      cidr_ipv4 = [
        "172.x.x.x/x",
        "220.75.180.0/24"
      ]
      source_security_group_id = null
      env                      = "stg"
    }
  ],
  elasticsearch-sg-ingress-rule = [
    {
      create_yn           = true
      security_group_name = "elasticsearch-sg" # 참조하는 보안그룹 이름을 넣어야 each.key로 구분 가능
      type                = "ingress"
      description         = "elasticsearch ssh security group inbound"
      from_port           = 22
      to_port             = 22
      protocol            = "tcp"
      cidr_ipv4 = [
        "172.x.x.x/x",
        "220.75.180.0/24"
      ]
      source_security_group_id = null
      env                      = "stg"
    },
    {
      create_yn           = true
      security_group_name = "elasticsearch-sg" # 참조하는 보안그룹 이름을 넣어야 each.key로 구분 가능
      type                = "ingress"
      description         = "elasticsearch es security group inbound"
      from_port           = 9200
      to_port             = 9200
      protocol            = "tcp"
      cidr_ipv4 = [
        "172.x.x.x/x",
        "220.75.180.0/24"
      ]
      source_security_group_id = null
      env                      = "stg"
    }
  ]
}

# EC2 보안그룹 아웃바운드 설정
ec2_security_group_egress_rules = {
  opensearch-sg-egress-rule = [
    {
      create_yn           = true
      security_group_name = "opensearch-sg"
      description         = "Opensearch security group outbound"
      type                = "egress"
      from_port           = 0
      to_port             = 0
      protocol            = "-1" # 모든 프로토콜 허용
      cidr_ipv4 = [
        "0.0.0.0/0"
      ]
      source_security_group_id = null
      env                      = "stg"
    }
  ],
  elasticsearch-sg-egress-rule = [
    {
      create_yn           = true
      security_group_name = "elasticsearch-sg"
      description         = "Elasticsearch security group outbound"
      type                = "egress"
      from_port           = 0
      to_port             = 0
      protocol            = "-1" # 모든 프로토콜 허용
      cidr_ipv4 = [
        "0.0.0.0/0"
      ]
      source_security_group_id = null
      env                      = "stg"
    }
  ]
}

# 생성을 원하는 N개의 EC2 정보 입력 
# -> EC2 성격별로 나누면 될 듯(Elasticsearch, Atlantis.. 등등)
ec2_instance = {
  opensearch = {
    create_yn = true

    # SSH key pair
    key_pair_name         = "opensearch-ec2-key"
    key_pair_algorithm    = "RSA"
    rsa_bits              = 4096
    local_file_name       = "keypair/xxxx.pem" # terraform key pair 생성 후 저장 경로 modules/aws/compute/ec2/...
    local_file_permission = "0600"             # 6(read + writer)00

    # EC2 Option
    ami_type                    = "custom"
    instance_type               = "t4g.large"
    subnet_type                 = "public"
    availability_zones          = "ap-northeast-2a"
    associate_public_ip_address = true
    disable_api_termination     = true
    instance_name               = "opensearch-es"
    security_group_name         = "opensearch-sg"
    env                         = "stg"
    script_file_name            = "install_opensearch.sh"

    # AMI filter
    owners = "self"
    filter = [
      {
        name   = "architecture"
        values = ["arm64"]
      },
      {
        name   = "name"
        values = ["*-opensearch-es-stg"]
      }
    ]
  },
  elasticsearch = {
    create_yn = false

    # SSH key pair
    key_pair_name         = "elasticsearch-ec2-key"
    key_pair_algorithm    = "RSA"
    rsa_bits              = 4096
    local_file_name       = "keypair/xxxx.pem" # terraform key pair 생성 후 저장 경로 modules/aws/compute/ec2/...
    local_file_permission = "0600"             # 6(read + writer)00

    # EC2 Option
    ami_type                    = "custom"
    instance_type               = "t4g.large"
    subnet_type                 = "public"
    availability_zones          = "ap-northeast-2a"
    associate_public_ip_address = true
    disable_api_termination     = true
    instance_name               = "elasticsearch"
    security_group_name         = "elasticsearch-sg"
    env                         = "stg"
    script_file_name            = "install_elasticsearch.sh"

    # AMI filter
    owners = "self"
    filter = [
      {
        name   = "architecture"
        values = ["arm64"]
      },
      {
        name   = "name"
        values = ["*-elasticsearch-stg"]
      }
    ]
  }
}

ec2_security_group_id = {}

########################################
# S3 설정
########################################
s3_bucket = {
  search-xxxx-tfstate = {
    create_yn   = false
    bucket_name = "search-xxxx-tfstate"
    bucket_versioning = {
      versioning_configuration = {
        status = "Enabled"
      }
    }
    server_side_encryption = {
      rule = {
        apply_server_side_encryption_by_default = {
          sse_algorithm = "AES256" # 암호화 Rule(규칙) 지정
        }
      }
    }
    public_access_block = {
      block_public_acls       = true
      block_public_policy     = true
      ignore_public_acls      = true
      restrict_public_buckets = true
    }
    env = "stg"
  }
}

########################################
# DynamoDB Table 설정
########################################
dynamodb_table = {
  search-xxx-xxx-lock = {
    create_yn    = false
    name         = "search-xxx-xxx-lock"
    hash_key     = "LockID"
    billing_mode = "PAY_PER_REQUEST"
    attribute = {
      name = "LockID"
      type = "S"
    }
    env = "stg"
  }
}

########################################
# 공통 태그 설정
########################################
tags = {
  project   = "search-xxxx"
  service   = "search-xxxx"
  teamTag   = "devops"
  managedBy = "terraform-admin"
  createdBy = "admin@funin.camp"
  env       = "stg"
}
