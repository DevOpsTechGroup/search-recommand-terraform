# export TF_VAR_ecs_container_image_version="1.0.0"
# pluralith graph

########################################
# 프로젝트 기본 설정
########################################
project_name = "search-recommand"
aws_region   = "ap-northeast-2"

availability_zones = [
  "ap-northeast-2a",
  "ap-northeast-2b",
  "ap-northeast-2c",
]
aws_account = "842675972665"
env         = "stg"

########################################
# 네트워크 설정
########################################
# IP 대역
# 10.0.0.0 - 10.255.255.255		-> 		16,777,216
# 172.16.0.0 - 172.31.255.255		-> 		1,048,576
# 192.168.0.0 - 192.168.255.255	->		65,536
# VPC ID(외부 data 변수를 통해 받음, 초기에는 빈값으로 셋팅)
vpc_id = ""

# VPC CIDR 대역 지정 - VPC CIDR는 개발환경에 적합한 크기로 설정
vpc_cidr = "172.21.0.0/16"

# 각 가용영역마다 하나의 public/private 서브넷 -> 가용 영역은 현재 2개
# 퍼블릭 서브넷 지정 -> 서브넷 당 256개 IP 사용 가능(5개는 빼야함)
# /24 -> 앞의 3개의 IP가 네트워크 주소, 나머지 8비트가 호스트 비트
public_subnets_cidr = [
  "172.21.10.0/24",
  "172.21.20.0/24",
  "172.21.30.0/24"
]

# 프라이빗 서브넷 지정
private_subnets_cidr = [
  "172.21.50.0/24",
  "172.21.60.0/24",
  "172.21.70.0/24",
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
# ALB 생성
# -> ALB의 KEY 이름과, Target Group 변수의 KEY 이름을 일치시켜야 함
alb = {
  "opensearch-alb" = {
    alb_name                             = "opensearch-alb"
    alb_internal                         = false
    alb_load_balancer_type               = "application"
    alb_enable_deletion_protection       = false # 생성하고 난 후에 true로 변경
    alb_enable_cross_zone_load_balancing = true
    alb_idle_timeout                     = 300
    env                                  = "stg"
  }
}

# ALB 보안그룹 생성
alb_security_group = "opensearch-alb-sg"

# ALB Listencer 생성
alb_listener = {
  "opensearch-alb-http-listener" = {
    name              = "opensearch-alb-http-listener"
    port              = 80
    protocol          = "HTTP"
    load_balancer_arn = "opensearch-alb" # 연결할 ALB 이름 지정
    default_action = {
      type             = "forward" # forward, redirect(다른 URL 전환), fixed-response(고정 응답값)
      target_group_arn = "opensearch-alb-tg"
    }
    env = "stg"
  },
}

# ALB Listener Rule 생성
alb_listener_rule = {
  "opensearch-alb-http-listener-rule" = {
    type              = "forward"
    path              = ["/vectorPlaylistSearch"]
    alb_listener_name = "opensearch-alb-http-listener"
    target_group_name = "opensearch-alb-tg"
    priority          = 1
  },
}

# ALB Target Group 생성
target_group = {
  "opensearch-alb-tg" = {
    target_group_name        = "opensearch-alb-tg"
    target_group_port        = 10091
    target_group_elb_type    = "ALB"
    target_group_target_type = "ip" # FARGATE는 IP로 지정해야 함, 동적으로 IP(ENI) 할당됨
    env                      = "stg"
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
    enabled = true # health_check 바깥에 위치해야 함
  },
}

########################################
# ECR 설정
########################################
# ECR 리포지토리 생성
ecr_repository = {
  "opensearch-vector-api" = {
    ecr_repository_name      = "opensearch-vector-api" # 리포지토리명
    env                      = "stg"                   # ECR 개발환경
    ecr_image_tag_mutability = "IMMUTABLE"             # image 버전 고유하게 관리할지 여부
    ecr_scan_on_push         = false                   # PUSH Scan 여부
    ecr_force_delete         = false
  }
}

########################################
# IAM 설정
########################################
# 사용자가 생성하는 역할(Role)
iam_custom_role = {
  "ecs-task-role" = {
    name    = "ecs-task-role"
    version = "2012-10-17"
    arn     = ""
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
  "ecs-task-exec-role" = {
    name    = "ecs-task-exec-role"
    version = "2012-10-17"
    arn     = ""
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
  "ecs-auto-scaling-role" = {
    name    = "ecs-auto-scaling-role"
    version = "2012-10-17"
    arn     = ""
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
  "ecs-task-role-policy" = {
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
  "ecs-task-exec-role-policy" = {
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
  "ecs-auto-scaling-role-policy" = {
    name = "AmazonEC2ContainerServiceAutoscaleRole"
    arn  = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
    env  = "stg"
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
  "ecs-task-role-attachment" = {
    role_name   = "ecs-task-role"
    policy_name = "ecs-task-role-policy"
    policy_type = "custom"
  },
  "ecs-task-exec-role" = {
    role_name   = "ecs-task-exec-role"
    policy_name = "ecs-task-exec-role-policy"
    policy_type = "custom"
  },
  "ecs-auto-scaling-role" = {
    role_name   = "ecs-auto-scaling-role"
    policy_name = "ecs-auto-scaling-role-policy"
    policy_type = "managed"
  }
}

####################
# ECS 클러스터 설정
####################
# ECS 클러스터 생성
ecs_cluster = {
  "opensearch-ecs-cluster" = {
    cluster_name = "opensearch-ecs-cluster"
    env          = "stg"
  }
}

# ECS Security Group 
# -> ecs_service 변수에 n개를 넣는건 이미 보안그룹이 존재하는 경우만 그렇게 사용 가능
ecs_security_group = "opensearch-ecs-sg"

# ECS IAM Role
ecs_task_role               = "ecs_task_role"
ecs_task_role_policy        = "ecs_task_role_policy"
ecs_task_exec_role          = "ecs_task_exec_role"
ecs_task_exec_role_policy   = "ecs_task_exec_role_policy"
ecs_auto_scaling_role       = "ecs_auto_scaling_role"
ecs_auto_scaling_policy_arn = "AmazonEC2ContainerServiceAutoscaleRole" # 기존에 생성되어 있는 정책을 참조

# ECS Container Image 버전
ecs_container_image_version = "1.0.0"

# ECS Task Definitions 생성
# TODO: containers.env 추가? + image_version 어떻게 받을지?
ecs_task_definitions = {
  "opensearch-vector-api-td" = {
    name                                    = "opensearch-vector-api-td"
    task_role                               = "ecs_task_role"
    task_exec_role                          = "ecs_task_exec_role"
    network_mode                            = "awsvpc"
    launch_type                             = "FARGATE"
    task_total_cpu                          = 1024 # ECS Task Total CPU
    task_total_memory                       = 2048 # ECS Task Total Mem
    runtime_platform_oprating_system_family = "LINUX"
    runtime_platform_cpu_architecture       = "X86_64"
    task_family                             = "opensearch-vector-api-td"
    cpu                                     = 1024
    memory                                  = 2048
    env                                     = "stg"
    ephemeral_storage                       = 21
    containers = [
      {
        name      = "opensearch-vector-api"
        image     = "842675972665.dkr.ecr.ap-northeast-2.amazonaws.com/opensearch-vector-api"
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
}

# ECS 서비스 생성
ecs_service = {
  "opensearch-ecs-service" = {
    launch_type                   = "FARGATE"
    service_role                  = "AWSServiceRoleForECS"
    deployment_controller         = "ECS"
    cluster_name                  = "opensearch-ecs-cluster"
    service_name                  = "opensearch-ecs-service"   # 서비스 이름
    desired_count                 = 1                          # Task 개수
    container_name                = "opensearch-vector-api"    # 컨테이너 이름
    container_port                = 10091                      # 컨테이너 포트
    task_definitions              = "opensearch-vector-api-td" # 테스크 지정
    env                           = "stg"                      # ECS Service 환경변수
    health_check_grace_period_sec = 250                        # 헬스 체크 그레이스 기간
    assign_public_ip              = false                      # 우선 public zone에 구성
    target_group_arn              = "opensearch-alb-tg"        # 연결되어야 하는 Target Group 지정
  },
}

# ECS Autoscaling
ecs_appautoscaling_target = {
  "opensearch-service" = {
    min_capacity       = 2                                                           # 최소 Task 2개가 항상 실행되도록 설정
    max_capacity       = 6                                                           # 최대 Task 6개까지 증가 할 수 있도록 설정
    resource_id        = "service/opensearch-ecs-cluster-stg/opensearch-service-stg" # TODO: 하드코딩된 부분 수정 -> AG를 적용할 대상 리소스 지정, 여기서는 ECS 서비스 ARN 형식의 일부 기재
    scalable_dimension = "ecs:service:DesiredCount"                                  # 조정할 수 있는 AWS 리소스의 특정 속성을 지정하는 필드
    service_namespace  = "ecs"
    cluster_name       = "opensearch-ecs-cluster" # ECS 클러스터명 지정
    service_name       = "opensearch-ecs-service" # ECS 서비스명 지정
  },
}

# ECS Autoscaling 정책
ecs_appautoscaling_target_policy = {
  "opensearch-ecs-service" = {
    scale_out = {
      name        = "ECSOpenSearchScaleOutPolicy" # 스케일 아웃 정책명
      policy_type = "StepScaling"                 # 정책 타입
      step_scaling_policy_conf = {
        adjustment_type         = "ChangeInCapacity" # 조정 방식 (퍼센트 증가: PercentChangeInCapacity, 개수: ChangeInCapacity)  
        cooldown                = 60                 # Autoscaling 이벤트 후 다음 이벤트까지 대기 시간(60초)
        metric_aggregation_type = "Average"          # 측정 지표의 집계 방식 (AVG: 평균)
        step_adjustment = {
          # Threshold 30 -> CPU 30 - 40% 스케일링
          "between_than_10_and_20" = {
            metric_interval_lower_bound = 0  # 트리거 조건의 최소 임계값(0%)
            metric_interval_upper_bound = 10 # 트리거 조건의 최대 임계값(10%)
            scaling_adjustment          = 1  # 조정 비율 (50% 비율로 ECS Task 증가 or 개수도 지정 가능)
          },
          # Threshold 30 -> CPU 40 - 50% 스케일링
          "between_than_20_and_30" = {
            metric_interval_lower_bound = 10
            metric_interval_upper_bound = 20
            scaling_adjustment          = 2
          },
          # Threshold 30 -> CPU 50 - n 스케일링
          "between_than_30_and_40" = {
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
  "opensearch-ecs-service" = {
    alarm_name          = "ECSOpenSearchScaleOutAlarm"
    comparison_operator = "GreaterThanOrEqualToThreshold" # 메트릭이 임계값보다 크거나 같으면 발동
    evaluation_periods  = "1"                             # 평가 주기는 1번 -> 1번만 조건에 맞아도 이벤트 발생
    metric_name         = "CPUUtilization"                # 메트릭 이름은 ECS의 CPU 사용률
    namespace           = "AWS/ECS"                       # 메트릭이 속한 네임스페이스
    period              = "60"                            # 60초마다 평가 
    statistic           = "Average"                       # 집계 방식은 평균으로
    threshold           = "30"                            # 30부터 스케일링 진행
    dimensions = {
      cluster_name = "opensearch-ecs-cluster"
      service_name = "opensearch-ecs-service"
    }
    env = "stg"
  }
}

########################################
# EC2 설정
########################################
ec2_security_group = {
  "search-recommand-bastion-sg" = {
    create                         = true
    ec2_security_group_name        = "search-recommand-bastion-sg"
    ec2_security_group_description = "search-recommand Bastion Host EC2"
    env                            = "stg"
  },
  "opensearch-es-sg" = {
    create                         = false
    ec2_security_group_name        = "opensearch-es-sg"
    ec2_security_group_description = "search-recommand Vector Opensearch EC2"
    env                            = "stg"
  }
}

# EC2 보안그룹 인바운드 설정
ec2_security_group_ingress_rules = {
  "search-recommand-bastion-sg-ingress-rule" = [
    {
      create                  = true
      ec2_security_group_name = "search-recommand-bastion-sg"
      type                    = "ingress"
      description             = "bastion host security group inbound"
      from_port               = 22
      to_port                 = 22
      protocol                = "tcp"
      cidr_ipv4 = [
        "183.111.245.0/24",
        "0.0.0.0/0"
      ]
      source_security_group_id = null
      env                      = "stg"
    }
  ],
  "opensearch-es-sg-ingress-rule" = [
    {
      create                  = false
      ec2_security_group_name = "opensearch-es-sg" # 참조하는 보안그룹 이름을 넣어야 each.key로 구분 가능
      type                    = "ingress"
      description             = "opensearch ssh security group inbound"
      from_port               = 22
      to_port                 = 22
      protocol                = "tcp"
      cidr_ipv4 = [
        "172.21.0.0/16"
      ]
      source_security_group_id = null
      env                      = "stg"
    },
    {
      create                  = false
      ec2_security_group_name = "opensearch-es-sg" # 참조하는 보안그룹 이름을 넣어야 each.key로 구분 가능
      type                    = "ingress"
      description             = "opensearch es security group inbound"
      from_port               = 9200
      to_port                 = 9200
      protocol                = "tcp"
      cidr_ipv4 = [
        "172.21.0.0/16"
      ]
      source_security_group_id = null
      env                      = "stg"
    }
  ]
}

# EC2 보안그룹 아웃바운드 설정
ec2_security_group_egress_rules = {
  "search-recommand-bastion-sg-egress-rule" = [
    {
      create                  = true
      ec2_security_group_name = "search-recommand-bastion-sg"
      description             = "bastion host to opensearch es"
      type                    = "egress"
      from_port               = 0
      to_port                 = 0
      protocol                = "-1" # 모든 프로토콜 허용
      cidr_ipv4 = [
        "0.0.0.0/0"
      ]
      source_security_group_id = null
      env                      = "stg"
    }
  ],
  "opensearch-es-sg-egress-rule" = [
    {
      create                  = false
      ec2_security_group_name = "opensearch-es-sg"
      description             = "opensearch es security group outbound"
      type                    = "egress"
      from_port               = 0
      to_port                 = 0
      protocol                = "-1" # 모든 프로토콜 허용
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
  "search-recommand-bastion" = {
    create = true

    # SSH key pair
    key_pair_name         = "search-recommand-ec2-key"
    key_pair_algorithm    = "RSA"
    rsa_bits              = 4096
    local_file_name       = "keypair/search-recommand-ec2-key.pem" # terraform key pair 생성 후 저장 경로 modules/aws/compute/ec2/...
    local_file_permission = "0600"                                 # 6(read + writer)00

    # EC2 Option
    ami_type                    = "managed"
    instance_type               = "t3.micro"
    subnet_type                 = "public"
    availability_zones          = "ap-northeast-2a"
    associate_public_ip_address = true
    disable_api_termination     = true
    ec2_instance_name           = "search-recommand-bastion"
    ec2_security_group_name     = "search-recommand-bastion-sg"
    env                         = "stg"
    script_file_name            = "install_bastion.sh" # 스크립트 파일명 지정
  },
  "opensearch-es" = {
    create = false

    # SSH key pair
    key_pair_name         = "opensearch-ec2-key"
    key_pair_algorithm    = "RSA"
    rsa_bits              = 4096
    local_file_name       = "keypair/opensearch-ec2-key.pem" # terraform key pair 생성 후 저장 경로 modules/aws/compute/ec2/...
    local_file_permission = "0600"                           # 6(read + writer)00

    # EC2 Option
    ami_type                    = "custom"
    instance_type               = "t4g.large"
    subnet_type                 = "private"
    availability_zones          = "ap-northeast-2a"
    associate_public_ip_address = false
    disable_api_termination     = true
    ec2_instance_name           = "opensearch-es"
    ec2_security_group_name     = "opensearch-es-sg"
    env                         = "stg"
    script_file_name            = "" # 스크립트 파일명 지정
  }
}

########################################
# S3 설정
########################################
s3_bucket = {
  terraform-funin-state = {
    create                 = true                    # 생성 여부 지정
    bucket_name            = "terraform-funin-state" # S3 버킷명
    versioning             = true                    # S3 버저닝 여부
    server_side_encryption = true                    # S3 Object 암호화 여부
    public_access_block    = true                    # S3 Public Access 제한 여부
  }
}

################
# 공통 태그 설정
################
tags = {
  env       = "stg"
  project   = "search-recommand"
  teamTag   = "devops"
  managedBy = "terraform-admin"
  createdBy = "devops-admin@gmail.com"
}
