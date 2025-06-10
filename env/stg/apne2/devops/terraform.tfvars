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
# 10.0.0.0 - 10.255.255.255   ->    16,777,216
# 172.16.0.0 - 172.31.255.255   ->    1,048,576
# 192.168.0.0 - 192.168.255.255 ->    65,536
# VPC ID - 외부 data 변수를 통해 받음, 초기에는 빈값으로 셋팅
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

# VPC Endpoint Gateway 설정
vpc_endpoint_gateway = {
  search-s3 = {
    endpoint_name     = "search-s3"
    service_name      = "com.amazonaws.ap-northeast-2.s3"
    vpc_endpoint_type = "Gateway"
  }
}

# VPC Endpoint Interface 설정
vpc_endpoint_interface = {
  search-ecr-dkr = {
    endpoint_name = "search-ecr-dkr"
    security_group_name = [
      "search-opensearch-api-sg"
    ]
    service_name        = "com.amazonaws.ap-northeast-2.ecr.dkr"
    vpc_endpoint_type   = "Interface"
    private_dns_enabled = true
  },
  search-ecr-api = {
    endpoint_name = "search-ecr-api"
    security_group_name = [
      "search-opensearch-api-sg"
    ]
    service_name        = "com.amazonaws.ap-northeast-2.ecr.api"
    vpc_endpoint_type   = "Interface"
    private_dns_enabled = true
  }
}

########################################
# 로드밸런서 설정
########################################
alb = {
  search-opensearch-alb = {
    name                             = "search-opensearch-alb"
    internal                         = false
    load_balancer_type               = "application"
    enable_deletion_protection       = false # 생성하고 난 후에 true로 변경
    enable_cross_zone_load_balancing = true
    idle_timeout                     = 300
    security_group_name              = "search-opensearch-alb-sg"
    env                              = "stg"
  },
  search-embed-alb = {
    name                             = "search-embed-alb"
    internal                         = true # Internal ALB
    load_balancer_type               = "application"
    enable_deletion_protection       = false # 생성하고 난 후에 true로 변경
    enable_cross_zone_load_balancing = true
    idle_timeout                     = 300
    security_group_name              = "search-embed-alb-sg"
    env                              = "stg"
  }
}

# ALB 보안그룹 생성
alb_security_group = {
  search-opensearch-alb-sg = {
    security_group_name = "search-opensearch-alb-sg"
    description         = "search-recommand alb security group"
    env                 = "stg"
  },
  search-embed-alb-sg = {
    security_group_name = "search-embed-alb-sg"
    description         = "search-embed alb security group"
    env                 = "stg"
  }
}

# ALB Listencer 생성
alb_listener = {
  search-opensearch-alb-http-listener = {
    name              = "search-opensearch-alb-http-listener"
    port              = 80
    protocol          = "HTTP"
    load_balancer_arn = "search-opensearch-alb" # 연결할 ALB 이름 지정
    default_action = {                          # TODO: 고정 응답 값 반환하도록 수정
      type = "fixed-response"                   # forward, redirect(다른 URL 전환), fixed-response(고정 응답값)
      # target_group_arn = "opensearch-alb-tg"
      fixed_response = {
        content_type = "text/plain"
        message_body = "Fixed response content"
        status_code  = "200"
      }
    }
    env = "stg"
  },
  search-embed-alb-blue-listener = {
    name              = "search-embed-alb-blue-listener"
    port              = 8000
    protocol          = "HTTP"
    load_balancer_arn = "search-embed-alb" # 연결할 ALB 이름 지정
    default_action = {
      type = "fixed-response"
      fixed_response = {
        content_type = "text/plain"
        message_body = "Fixed response content"
        status_code  = "200"
      }
    }
    env = "stg"
  },
  search-embed-alb-green-listener = {
    name              = "search-embed-alb-green-listener"
    port              = 8001
    protocol          = "HTTP"
    load_balancer_arn = "search-embed-alb" # 연결할 ALB 이름 지정
    default_action = {
      type = "fixed-response"
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
  search-opensearch-alb-http-listener-rule = {
    type              = "forward"                             # forward, redirect, fixed-response
    path              = ["/opensearch/*"]                     # URL 경로
    alb_listener_name = "search-opensearch-alb-http-listener" # 연결할 ALB Listener명
    target_group_name = "search-opensearch-alb-tg"            # 연결할 Target Group명
    priority          = 1
  },
  search-opensearch-alb-swagger-listener-rule = {
    type              = "forward"                             # forward, redirect, fixed-response
    path              = ["/v1/opensearch/*"]                  # URL 경로
    alb_listener_name = "search-opensearch-alb-http-listener" # 연결할 ALB Listener명
    target_group_name = "search-opensearch-alb-tg"            # 연결할 Target Group명
    priority          = 2
  },
  search-embed-alb-blue-listener-rule = {
    type              = "forward"
    path              = ["/embed/*"]
    alb_listener_name = "search-embed-alb-blue-listener"
    target_group_name = "search-embed-alb-blue-tg"
    priority          = 1
  },
  search-embed-alb-green-listener-rule = {
    type              = "forward"
    path              = ["/embed/*"]
    alb_listener_name = "search-embed-alb-green-listener"
    target_group_name = "search-embed-alb-green-tg"
    priority          = 2
  }
}

# ALB Target Group 생성
target_group = {
  search-opensearch-alb-tg = {
    name        = "search-opensearch-alb-tg"
    port        = 8443
    elb_type    = "ALB"
    protocol    = "HTTP" # HTTP(ALB) or TCP(NLB)
    target_type = "ip"   # FARGATE는 IP로 지정해야 함, 동적으로 IP(ENI) 할당됨
    env         = "stg"
    health_check = {
      path                = "/health-check"
      enabled             = true
      healthy_threshold   = 3
      interval            = 30
      port                = 8443
      protocol            = "HTTP"
      timeout             = 15
      unhealthy_threshold = 5
      internal            = false
    }
  },
  search-embed-alb-blue-tg = {
    name        = "search-embed-alb-blue-tg"
    port        = 8000
    elb_type    = "ALB"
    protocol    = "HTTP"
    target_type = "ip"
    env         = "stg"
    health_check = {
      path                = "/health-check"
      enabled             = true
      healthy_threshold   = 3
      interval            = 30
      port                = 8000
      protocol            = "HTTP"
      timeout             = 15
      unhealthy_threshold = 5
      internal            = false
    }
  },
  search-embed-alb-green-tg = {
    name        = "search-embed-alb-green-tg"
    port        = 8000
    elb_type    = "ALB"
    protocol    = "HTTP"
    target_type = "ip"
    env         = "stg"
    health_check = {
      path                = "/health-check"
      enabled             = true
      healthy_threshold   = 3
      interval            = 30
      port                = 8000
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
  search-opensearch-api = {
    ecr_repository_name      = "search-opensearch-api" # 리포지토리명
    env                      = "stg"                   # ECR 개발환경
    ecr_image_tag_mutability = "IMMUTABLE"             # image 버전 고유하게 관리할지 여부
    ecr_scan_on_push         = false                   # PUSH Scan 여부
    ecr_force_delete         = false
  },
  search-embed-api = {
    ecr_repository_name      = "search-embed-api" # 리포지토리명
    env                      = "stg"              # ECR 개발환경
    ecr_image_tag_mutability = "IMMUTABLE"        # image 버전 고유하게 관리할지 여부
    ecr_scan_on_push         = false              # PUSH Scan 여부
    ecr_force_delete         = false
  },
  search-embed-batch = {
    ecr_repository_name      = "search-embed-batch" # 리포지토리명
    env                      = "stg"                # ECR 개발환경
    ecr_image_tag_mutability = "IMMUTABLE"          # image 버전 고유하게 관리할지 여부
    ecr_scan_on_push         = false                # PUSH Scan 여부
    ecr_force_delete         = false
  }
}

########################################
# IAM 설정
########################################
# 사용자가 생성하는 역할(Role)
iam_custom_role = {
  # ECS Task Role
  search-ecs-task-role = {
    name    = "search-ecs-task-role"
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
  # ECS Task Execution Role
  search-ecs-task-exec-role = {
    name    = "search-ecs-task-exec-role"
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
  # Atlantis EC2 Service Role
  search-atlantis-deploy-role = {
    name    = "search-atlantis-deploy-role"
    version = "2012-10-17"
    arn     = ""
    statement = {
      Sid    = "EC2AtlantisRole"
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }
    env = "stg"
  },
  # Jenkins Deploy Role
  search-jenkins-deploy-role = {
    name    = "search-jenkins-deploy-role"
    version = "2012-10-17"
    arn     = ""
    statement = {
      Sid    = "JenkinsDeployRole"
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }
    env = "stg"
  },
  # ECS Auto Scaling Role
  search-ecs-auto-scaling-role = {
    name    = "search-ecs-auto-scaling-role"
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
  },
  # CodeDeploy Service Role
  search-codedeploy-service-role = {
    name    = "search-codedeploy-service-role"
    version = "2012-10-17"
    arn     = ""
    statement = {
      Sid    = "CodeDeployServiceRole"
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "codedeploy.amazonaws.com"
      }
    }
    env = "stg"
  },
}

# 사용자가 생성하는 정책(Policy)
iam_custom_policy = {
  # ECS Task Policy
  search-ecs-task-policy = {
    name        = "search-ecs-task-policy"
    description = "Policy For ECS Task Role"
    version     = "2012-10-17"
    statement = {
      Sid = "ECSTaskPolicy"
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
  # ECS Task Execution Policy
  search-ecs-task-exec-policy = {
    name        = "search-ecs-task-exec-policy"
    description = "Policy for ecs task execution role"
    version     = "2012-10-17"
    statement = {
      Sid = "ECSTaskExecPolicy"
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
  },
  # Atlantis Policy
  search-atlantis-deploy-policy = {
    name        = "search-atlantis-deploy-policy"
    description = "Policy for atlantis role"
    version     = "2012-10-17"
    statement = {
      Sid = "AtlantisMainPolicy"
      Action = [
        "ec2:*",
        "iam:*",
        "iam:PassRole",
        "autoscaling:*",
        "elasticloadbalancing:*",
        "logs:*",
        "cloudwatch:*",
        "s3:*",
        "ssm:GetParameter",
        "ecr:*",
        "ecs:*",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
        "dynamodb:UpdateItem",
        "dynamodb:DescribeTable"
      ]
      Effect = "Allow"
      Resource = [
        "*"
      ]
    }
    env = "stg"
  },
  # Jenkins ECS Policy - Jenkins를 통해 ECS Service 생성 등등의 작업 수행
  search-jenkins-deploy-policy = {
    name        = "search-jenkins-deploy-policy"
    description = "Policy for Jenkins to deploy ECS and ECR"
    version     = "2012-10-17"
    statement = {
      Sid = "JenkinsDeployMainPolicy"
      Action = [
        "ecs:UpdateService",
        "ecs:Describe*",
        "ecs:List*",
        "ecs:RegisterTaskDefinition",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "iam:PassRole"
      ]
      Effect   = "Allow"
      Resource = ["*"] # 추후 범위 좁히기
    }
    env = "stg"
  }
}

# 기존 AWS에서 제공되는 정책 사용(Policy) - data "aws_iam_policy" "existing_policy" { }
# 아래 변수의 경우 Policy를 사용하기는 하는데, 기존 AWS Managed Policy를 사용하는 경우 사용하는 변수
iam_managed_policy = {
  # ECS Auto Scaling Policy
  search-ecs-auto-scaling-policy = {
    name = "AmazonEC2ContainerServiceAutoscaleRole"
    arn  = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
    env  = "stg"
  },
  # CodeDeploy Service Role
  search-codedeploy-service-role = {
    name = "AWSCodeDeployRoleForECS"
    arn  = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
    env  = "stg"
  }
}

# IAM 역할(Role)에 정책(Policy)을 연결
iam_policy_attachment = {
  search-ecs-task-role-attachment = {
    role_name   = "search-ecs-task-role"
    policy_name = "search-ecs-task-policy"
  },
  search-ecs-task-exec-role = {
    role_name   = "search-ecs-task-exec-role"
    policy_name = "search-ecs-task-exec-policy"
  },
  search-atlantis-deploy-role = {
    role_name   = "search-atlantis-deploy-role"
    policy_name = "search-atlantis-deploy-policy"
  },
  search-jenkins-deploy-role = {
    role_name   = "search-jenkins-deploy-role"
    policy_name = "search-jenkins-deploy-policy"
  },
  search-ecs-auto-scaling-role = {
    role_name   = "search-ecs-auto-scaling-role"
    policy_name = "search-ecs-auto-scaling-policy" # iam_managed_policy 변수의 KEY로 지정
  },
  search-codedeploy-service-role = {
    role_name   = "search-codedeploy-service-role"
    policy_name = "search-codedeploy-service-role" # iam_managed_policy 변수의 KEY로 지정
  },
}

# IAM 인스턴스 프로파일(instance profile)
iam_instance_profile = {
  search-atlantis-instance-profile = {
    name      = "search-atlantis-instance-profile"
    role_name = "search-atlantis-deploy-role"
  },
  search-jenkins-instance-profile = {
    name      = "search-jenkins-instance-profile"
    role_name = "search-jenkins-deploy-role"
  }
}

########################################
# ECS 클러스터 설정
########################################
ecs_cluster = {
  search-ecs-cluster = {
    cluster_name = "search-ecs-cluster"
    env          = "stg"
  }
}

# ECS 보안그룹(security group) 
ecs_security_group = {
  search-opensearch-api-sg = {
    security_group_name = "search-opensearch-api-sg"
    description         = "opensearch ecs api security group"
    env                 = "stg"
  },
  search-embed-api-sg = {
    security_group_name = "search-embed-api-sg"
    description         = "embed api security group"
    env                 = "stg"
  }
}

# ECS Task Definitions 생성
# TODO: containers.env 추가? + image_version 어떻게 받을지?
ecs_task_definitions = {
  search-opensearch-api-td = {
    name                                    = "search-opensearch-api-td"
    task_role                               = "ecs_task_role"
    task_exec_role                          = "ecs_task_exec_role"
    network_mode                            = "awsvpc"
    launch_type                             = "FARGATE"
    task_total_cpu                          = 1024 # ECS Task Total CPU
    task_total_memory                       = 2048 # ECS Task Total Mem
    runtime_platform_oprating_system_family = "LINUX"
    runtime_platform_cpu_architecture       = "X86_64"
    task_family                             = "search-opensearch-api-td"
    env                                     = "stg"
    volume = {
      name = "search-opensearch-shared-volume"
    }
    ephemeral_storage = 21
    containers = [
      {
        name      = "search-opensearch-api"
        image     = "842675972665.dkr.ecr.ap-northeast-2.amazonaws.com/search-opensearch-api"
        version   = "1.0.0" # container image version은 ecs_container_image_version 변수 사용
        cpu       = 256     # container cpu
        memory    = 512     # container mem
        port      = 8443
        protocol  = "tcp"
        essential = true
        env_variables = {
          "TZ"                     = "Asia/Seoul"
          "SPRING_PROFILES_ACTIVE" = "stage"
        }
        mount_points = []
        health_check = {
          command  = "curl --fail http://127.0.0.1:8443/health-check || exit 1"
          interval = 30
          timeout  = 10
          retries  = 3
        }
        env = "stg"
      }
    ]
  },
  search-embed-api-td = {
    name                                    = "search-embed-api-td"
    task_role                               = "ecs_task_role"
    task_exec_role                          = "ecs_task_exec_role"
    network_mode                            = "awsvpc"
    launch_type                             = "FARGATE"
    task_total_cpu                          = 1024
    task_total_memory                       = 2048
    runtime_platform_oprating_system_family = "LINUX"
    runtime_platform_cpu_architecture       = "X86_64"
    task_family                             = "search-embed-api-td"
    env                                     = "stg"
    volume = {
      name = "search-embed-shared-volume"
    }
    ephemeral_storage = 21
    containers = [
      {
        name      = "search-embed-api"
        image     = "842675972665.dkr.ecr.ap-northeast-2.amazonaws.com/search-embed-api"
        version   = "1.0.0"
        cpu       = 256
        memory    = 512
        port      = 8000
        protocol  = "tcp"
        essential = true
        env_variables = {
          "TZ"                     = "Asia/Seoul"
          "SPRING_PROFILES_ACTIVE" = "stage"
        }
        mount_points = []
        health_check = {
          command  = "curl --fail http://127.0.0.1:8000/health-check || exit 1"
          interval = 30
          timeout  = 10
          retries  = 3
        }
        env = "stg"
      }
    ]
  }
}

# ECS 서비스 생성
ecs_service = {
  search-opensearch-ecs-service = {
    subnets                       = "private"
    launch_type                   = "FARGATE"              # ECS Launch Type
    service_role                  = "AWSServiceRoleForECS" # ECS Service Role
    deployment_controller         = "ECS"                  # ECS Deployment Controller (ECS | CODE_DEPLOY | EXTERNAL)
    deployment_circuit_breaker    = true
    cluster_name                  = "search-ecs-cluster"            # ECㅂS Cluster명
    service_name                  = "search-opensearch-ecs-service" # 서비스 이름
    desired_count                 = 0                               # Task 개수
    container_name                = "search-opensearch-api"         # 컨테이너 이름
    container_port                = 8443                            # 컨테이너 포트
    task_definitions              = "search-opensearch-api-td"      # 테스크 지정
    env                           = "stg"                           # ECS Service 환경변수
    health_check_grace_period_sec = 250                             # 헬스 체크 그레이스 기간
    assign_public_ip              = true                            # 우선 public zone에 구성
    target_group_arn              = "search-opensearch-alb-tg"      # 연결되어야 하는 Target Group 지정
    security_group_name           = "search-opensearch-api-sg"      # 보안그룹 이름
  },
  search-embed-ecs-service = {
    subnets                       = "private"
    launch_type                   = "FARGATE"              # ECS Launch Type
    service_role                  = "AWSServiceRoleForECS" # ECS Service Role
    deployment_controller         = "CODE_DEPLOY"          # ECS Deployment Controller (ECS | CODE_DEPLOY | EXTERNAL)
    deployment_circuit_breaker    = false
    cluster_name                  = "search-ecs-cluster"       # ECS Cluster명
    service_name                  = "search-embed-ecs-service" # 서비스 이름
    desired_count                 = 0                          # Task 개수
    container_name                = "search-embed-api"         # 컨테이너 이름
    container_port                = 8000                       # 컨테이너 포트
    task_definitions              = "search-embed-api-td"      # 테스크 지정
    env                           = "stg"                      # ECS Service 환경변수
    health_check_grace_period_sec = 250                        # 헬스 체크 그레이스 기간
    assign_public_ip              = true                       # 우선 public zone에 구성
    target_group_arn              = "search-embed-alb-blue-tg" # 연결되어야 하는 Target Group 지정 # FIXME: 수정 필요 -> TG 2개 연결
    security_group_name           = "search-embed-api-sg"      # 보안그룹 이름
  }
}

# ECS Autoscaling
# TODO: resource_id 이 부분은 module에서 받을 수 있으면 받도록 수정 필요
ecs_appautoscaling_target = {
  search-opensearch-ecs-service = {
    min_capacity       = 1                                                                  # 최소 Task 2개가 항상 실행되도록 설정
    max_capacity       = 3                                                                  # 최대 Task 6개까지 증가 할 수 있도록 설정
    resource_id        = "service/search-ecs-cluster-stg/search-opensearch-ecs-service-stg" # TODO: 하드코딩된 부분 수정 -> AG를 적용할 대상 리소스 지정, 여기서는 ECS 서비스 ARN 형식의 일부 기재
    scalable_dimension = "ecs:service:DesiredCount"                                         # 조정할 수 있는 AWS 리소스의 특정 속성을 지정하는 필드
    service_namespace  = "ecs"
    cluster_name       = "search-ecs-cluster"            # ECS 클러스터명 지정
    service_name       = "search-opensearch-ecs-service" # ECS 서비스명 지정
  },
  search-embed-ecs-service = {
    min_capacity       = 1
    max_capacity       = 3
    resource_id        = "service/search-ecs-cluster-stg/search-embed-ecs-service-stg"
    scalable_dimension = "ecs:service:DesiredCount"
    service_namespace  = "ecs"
    cluster_name       = "search-ecs-cluster"
    service_name       = "search-embed-ecs-service"
  }
}

# ECS Autoscaling 정책
ecs_appautoscaling_target_policy = {
  search-opensearch-ecs-service = {
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
          }
        }
      }
    }
  },
  search-embed-ecs-service = {
    scale_out = {
      name        = "ECSEmbedScaleOutPolicy"
      policy_type = "StepScaling"
      step_scaling_policy_conf = {
        adjustment_type         = "ChangeInCapacity"
        cooldown                = 60
        metric_aggregation_type = "Average"
        step_adjustment = {
          between_than_10_and_20 = {
            metric_interval_lower_bound = 0
            metric_interval_upper_bound = 10
            scaling_adjustment          = 1
          },
          between_than_20_and_30 = {
            metric_interval_lower_bound = 10
            metric_interval_upper_bound = 20
            scaling_adjustment          = 2
          },
          between_than_30_and_40 = {
            metric_interval_lower_bound = 20
            scaling_adjustment          = 3
          },
        }
      }
    }
  }
}

# ECS Autoscaling Cloudwatch policy
ecs_cpu_scale_out_alert = {
  search-opensearch-ecs-service = {
    alarm_name          = "ECSOpenSearchScaleOutAlarm"
    comparison_operator = "GreaterThanOrEqualToThreshold" # 메트릭이 임계값보다 크거나 같으면 발동
    evaluation_periods  = "1"                             # 평가 주기는 1번 -> 1번만 조건에 맞아도 이벤트 발생
    metric_name         = "CPUUtilization"                # 메트릭 이름은 ECS의 CPU 사용률
    namespace           = "AWS/ECS"                       # 메트릭이 속한 네임스페이스
    period              = "60"                            # 60초마다 평가 
    statistic           = "Average"                       # 집계 방식은 평균으로
    threshold           = "30"                            # 30부터 스케일링 진행
    dimensions = {
      cluster_name = "search-ecs-cluster"
      service_name = "search-opensearch-ecs-service"
    }
    env = "stg"
  },
  search-embed-ecs-service = {
    alarm_name          = "ECSEmbedScaleOutAlarm"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = "1"
    metric_name         = "CPUUtilization"
    namespace           = "AWS/ECS"
    period              = "60"
    statistic           = "Average"
    threshold           = "30"
    dimensions = {
      cluster_name = "search-ecs-cluster"
      service_name = "search-embed-ecs-service"
    }
    env = "stg"
  }
}

ecs_security_group_id = {}

########################################
# EC2 설정
########################################
ec2_instance = {
  search-jenkins-test-01 = {
    create_yn                   = false
    ami_type                    = "offer"
    instance_type               = "t3.medium"
    subnet_type                 = "public"
    availability_zones          = "ap-northeast-2a"
    associate_public_ip_address = true
    disable_api_termination     = true
    instance_name               = "search-jenkins-test-01"
    security_group_name         = "search-jenkins-sg"
    env                         = "stg"
    script_file_name            = ""
    iam_instance_profile        = "search-jenkins-instance-profile"
    key_pair_name               = "search-jenkins-test"
    private_ip                  = "172.21.10.240"

    root_block_device = {
      volume_type           = "gp3"
      volume_size           = 30
      delete_on_termination = true
      encrypted             = false
    }

    owners = "self"
    filter = [
      {
        name   = "virtualization-type"
        values = ["hvm"]
      },
      {
        name   = "architecture"
        values = ["x86_64"]
      },
      {
        name   = "name"
        values = ["search-jenkins-test-01-*"]
      }
    ]
  }
  search-opensearch-test-sn01 = { // single node
    create_yn                   = true
    ami_type                    = "custom"
    instance_type               = "t4g.large"
    subnet_type                 = "public"
    availability_zones          = "ap-northeast-2a"
    associate_public_ip_address = true
    disable_api_termination     = true
    instance_name               = "search-opensearch-test-sn01"
    security_group_name         = "search-opensearch-sg"
    env                         = "stg"
    script_file_name            = ""
    iam_instance_profile        = ""
    key_pair_name               = "search-opensearch-key"
    private_ip                  = "172.21.10.220"

    root_block_device = {
      volume_type           = "gp3"
      volume_size           = 30
      delete_on_termination = true
      encrypted             = false
    }

    owners = "self"
    filter = [
      {
        name   = "virtualization-type"
        values = ["hvm"]
      },
      {
        name   = "architecture"
        values = ["arm64"]
      },
      {
        name   = "name"
        values = ["search-opensearch-test-*"]
      }
    ]
  },
  search-embed-test-01 = {
    create_yn                   = true
    ami_type                    = "custom"
    instance_type               = "t3.large"
    subnet_type                 = "public"
    availability_zones          = "ap-northeast-2a"
    associate_public_ip_address = true
    disable_api_termination     = true
    instance_name               = "search-embed-test-01"
    security_group_name         = "search-embed-sg" # TODO: EC2 -> ECS로 전환 필요
    env                         = "stg"
    script_file_name            = ""
    iam_instance_profile        = ""
    key_pair_name               = "search-embed-key"
    private_ip                  = "172.21.10.230"

    root_block_device = {
      volume_type           = "gp3"
      volume_size           = 20
      delete_on_termination = true
      encrypted             = false
    }

    owners = "self"
    filter = [
      {
        name   = "virtualization-type"
        values = ["hvm"]
      },
      {
        name   = "architecture"
        values = ["x86_64"]
      },
      {
        name   = "name"
        values = ["search-embed-test-*"]
      }
    ]
  },
  # search-opensearch-test-c01 = {
  #   create_yn                   = true
  #   ami_type                    = "custom"
  #   instance_type               = "t4g.medium"
  #   subnet_type                 = "public"
  #   availability_zones          = "ap-northeast-2a"
  #   associate_public_ip_address = true
  #   disable_api_termination     = true
  #   instance_name               = "search-opensearch-test-c01"
  #   security_group_name         = "search-opensearch-sg"
  #   env                         = "stg"
  #   script_file_name            = "install_os_c01.sh"
  #   iam_instance_profile        = ""
  #   key_pair_name               = "search-opensearch-key"
  #   private_ip                  = "172.21.10.200"

  #   root_block_device = {
  #     volume_type           = "gp3"
  #     volume_size           = 30
  #     delete_on_termination = true
  #     encrypted             = false
  #   }

  #   owners = "amazon"
  #   filter = [
  #     {
  #       name   = "virtualization-type"
  #       values = ["hvm"]
  #     },
  #     {
  #       name   = "architecture"
  #       values = ["arm64"]
  #     },
  #     {
  #       name   = "name"
  #       values = ["al2023-ami-*-arm64"]
  #     }
  #   ]
  # },
  # search-opensearch-test-c02 = {
  #   create_yn                   = true
  #   ami_type                    = "custom"
  #   instance_type               = "t4g.medium"
  #   subnet_type                 = "public"
  #   availability_zones          = "ap-northeast-2b"
  #   associate_public_ip_address = true
  #   disable_api_termination     = true
  #   instance_name               = "search-opensearch-test-c02"
  #   security_group_name         = "search-opensearch-sg"
  #   env                         = "stg"
  #   script_file_name            = "install_os_c02.sh"
  #   iam_instance_profile        = ""
  #   key_pair_name               = "search-opensearch-key"
  #   private_ip                  = "172.21.20.200"

  #   root_block_device = {
  #     volume_type           = "gp3"
  #     volume_size           = 30
  #     delete_on_termination = true
  #     encrypted             = false
  #   }

  #   owners = "amazon"
  #   filter = [
  #     {
  #       name   = "virtualization-type"
  #       values = ["hvm"]
  #     },
  #     {
  #       name   = "architecture"
  #       values = ["arm64"]
  #     },
  #     {
  #       name   = "name"
  #       values = ["al2023-ami-*-arm64"]
  #     }
  #   ]
  # },
  # search-opensearch-test-c03 = {
  #   create_yn                   = true
  #   ami_type                    = "custom"
  #   instance_type               = "t4g.medium"
  #   subnet_type                 = "public"
  #   availability_zones          = "ap-northeast-2c"
  #   associate_public_ip_address = true
  #   disable_api_termination     = true
  #   instance_name               = "search-opensearch-test-c03"
  #   security_group_name         = "search-opensearch-sg"
  #   env                         = "stg"
  #   script_file_name            = "install_os_c03.sh"
  #   iam_instance_profile        = ""
  #   key_pair_name               = "search-opensearch-key"
  #   private_ip                  = "172.21.30.200"

  #   root_block_device = {
  #     volume_type           = "gp3"
  #     volume_size           = 30
  #     delete_on_termination = true
  #     encrypted             = false
  #   }

  #   owners = "amazon"
  #   filter = [
  #     {
  #       name   = "virtualization-type"
  #       values = ["hvm"]
  #     },
  #     {
  #       name   = "architecture"
  #       values = ["arm64"]
  #     },
  #     {
  #       name   = "name"
  #       values = ["al2023-ami-*-arm64"]
  #     }
  #   ]
  # },
  # search-opensearch-test-d01 = {
  #   create_yn                   = true
  #   ami_type                    = "custom"
  #   instance_type               = "t4g.large"
  #   subnet_type                 = "public"
  #   availability_zones          = "ap-northeast-2a"
  #   associate_public_ip_address = true
  #   disable_api_termination     = true
  #   instance_name               = "search-opensearch-test-d01"
  #   security_group_name         = "search-opensearch-sg"
  #   env                         = "stg"
  #   script_file_name            = "install_os_d01.sh"
  #   iam_instance_profile        = ""
  #   key_pair_name               = "search-opensearch-key"
  #   private_ip                  = "172.21.10.210"

  #   root_block_device = {
  #     volume_type           = "gp3"
  #     volume_size           = 30
  #     delete_on_termination = true
  #     encrypted             = false
  #   }

  #   owners = "amazon"
  #   filter = [
  #     {
  #       name   = "virtualization-type"
  #       values = ["hvm"]
  #     },
  #     {
  #       name   = "architecture"
  #       values = ["arm64"]
  #     },
  #     {
  #       name   = "name"
  #       values = ["al2023-ami-*-arm64"]
  #     }
  #   ]
  # },
  # search-opensearch-test-d02 = {
  #   create_yn                   = true
  #   ami_type                    = "custom"
  #   instance_type               = "t4g.large"
  #   subnet_type                 = "public"
  #   availability_zones          = "ap-northeast-2b"
  #   associate_public_ip_address = true
  #   disable_api_termination     = true
  #   instance_name               = "search-opensearch-test-d02"
  #   security_group_name         = "search-opensearch-sg"
  #   env                         = "stg"
  #   script_file_name            = "install_os_d02.sh"
  #   iam_instance_profile        = ""
  #   key_pair_name               = "search-opensearch-key"
  #   private_ip                  = "172.21.20.210"

  #   root_block_device = {
  #     volume_type           = "gp3"
  #     volume_size           = 30
  #     delete_on_termination = true
  #     encrypted             = false
  #   }

  #   owners = "amazon"
  #   filter = [
  #     {
  #       name   = "virtualization-type"
  #       values = ["hvm"]
  #     },
  #     {
  #       name   = "architecture"
  #       values = ["arm64"]
  #     },
  #     {
  #       name   = "name"
  #       values = ["al2023-ami-*-arm64"]
  #     }
  #   ]
  # },
  # search-opensearch-test-d03 = {
  #   create_yn                   = true
  #   ami_type                    = "custom"
  #   instance_type               = "t4g.large"
  #   subnet_type                 = "public"
  #   availability_zones          = "ap-northeast-2c"
  #   associate_public_ip_address = true
  #   disable_api_termination     = true
  #   instance_name               = "search-opensearch-test-d03"
  #   security_group_name         = "search-opensearch-sg"
  #   env                         = "stg"
  #   script_file_name            = "install_os_d03.sh"
  #   iam_instance_profile        = ""
  #   key_pair_name               = "search-opensearch-key"
  #   private_ip                  = "172.21.30.210"

  #   root_block_device = {
  #     volume_type           = "gp3"
  #     volume_size           = 30
  #     delete_on_termination = true
  #     encrypted             = false
  #   }

  #   owners = "amazon"
  #   filter = [
  #     {
  #       name   = "virtualization-type"
  #       values = ["hvm"]
  #     },
  #     {
  #       name   = "architecture"
  #       values = ["arm64"]
  #     },
  #     {
  #       name   = "name"
  #       values = ["al2023-ami-*-arm64"]
  #     }
  #   ]
  # },
  # search-atlantis-01 = {
  #   create_yn                   = true
  #   ami_type                    = "custom"
  #   instance_type               = "t2.micro" #TODO: Volume size가 너무 작아서 올리다가 뻑남 + shell script 수정 필요 + atlantis 테스트 필요
  #   subnet_type                 = "public"
  #   availability_zones          = "ap-northeast-2a"
  #   associate_public_ip_address = true
  #   disable_api_termination     = true
  #   instance_name               = "search-atlantis-01"
  #   security_group_name         = "search-atlantis-sg"
  #   env                         = "stg"
  #   script_file_name            = "install_atlantis.sh"
  #   iam_instance_profile        = "search-atlantis-terraform-instance-profile"
  #   key_pair_name               = "search-atlantis-key"

  #   root_block_device = {
  #     volume_type           = "gp2"
  #     volume_size           = 30
  #     delete_on_termination = true
  #     encrypted             = false
  #   }

  #   owners = "amazon"
  #   # amazon linux2 : amzn2-ami-hvm-*-x86_64-gp2
  #   # amazon linux 2023 : al2023-ami-*-x86_64
  #   # Ubuntu 22.04 : ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-* / 099720109477
  #   filter = [
  #     {
  #       name   = "virtualization-type",
  #       values = ["hvm"] # t2 계열은 HVM만 지원
  #     },
  #     {
  #       name   = "architecture"
  #       values = ["x86_64"]
  #     },
  #     {
  #       name   = "name"
  #       values = ["al2023-ami-*-x86_64"]
  #     }
  #   ]
  # }
}

# EC2 보안그룹 생성
ec2_security_group = {
  search-jenkins-sg = {
    security_group_name = "search-jenkins-sg"
    description         = "search-recommand vector jenkins ec2"
    env                 = "stg"
  },
  search-opensearch-sg = {
    security_group_name = "search-opensearch-sg"
    description         = "search-recommand vector opensearch ec2"
    env                 = "stg"
  },
  search-embed-sg = {
    security_group_name = "search-embed-sg"
    description         = "search-recommand elasticsearch ec2"
    env                 = "stg"
  },
  # search-atlantis-sg = {
  #   security_group_name = "search-atlantis-sg"
  #   description         = "search-recommand atlantis ec2"
  #   env                 = "stg"
  # }
}

ec2_security_group_id = {}

# EC2 key pair
ec2_key_pair = {
  search-jenkins-test = {
    name = "search-jenkins-test"
    env  = "stg"
  },
  search-opensearch-key = {
    name = "search-opensearch-key"
    env  = "stg"
  },
  search-embed-key = {
    name = "search-embed-key"
    env  = "stg"
  },
  # search-atlantis-key = {
  #   name = "search-atlantis-key"
  #   env  = "stg"
  # }
}

########################################
# S3 설정
########################################
s3_bucket = {
  search-recommand-terraform-tfstate = {
    bucket_name = "search-recommand-terraform-tfstate"
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
# CI/CD 설정
########################################
# CodeDeploy Application 생성
codedeploy_app = {
  search-embed-api-codedeploy-app = {
    compute_platform = "ECS"                             # Compute 플랫폼 지정 (ECS, Lambda, Server)
    name             = "search-embed-api-codedeploy-app" # CodeDeploy Application명
    env              = "stg"
  }
}

# CodeDeploy 배포 그룹 생성
codedeploy_deployment_group = {
  search-embed-api-codedeploy-deployment-group = {
    app_name               = "search-embed-api-codedeploy-app"              # CodeDeploy Application명 지정
    deployment_group_name  = "search-embed-api-codedeploy-deployment-group" # 배포 그룹명
    deployment_config_name = "CodeDeployDefault.ECSCanary10Percent5Minutes" # 10% 까나리아 배포 구성

    # 배포 실패 시 자동 롤백 설정 
    auto_rollback_configuration = {
      enabled = true                 # 자동 롤백 활성화
      events  = "DEPLOYMENT_FAILURE" # 배포 실패 시 자동 롤백 수행
    }

    # Blue/Green 배포 전략 관련 설정
    blue_green_deployment_config = {
      deployment_ready_option = {
        action_on_timeout    = "STOP_DEPLOYMENT" # 테스트 완료 후 대기 시간 초과 시 자동으로 배포 계속
        wait_time_in_minutes = 5                 # 테스트 환경에서 대기할 시간 (분)
      }
      terminate_blue_instances_on_deployment_success = {
        action                           = "TERMINATE" # 배포 성공 시 기존(Blue) 인스턴스 종료
        termination_wait_time_in_minutes = 5           # 배포 성공 후 기존(Blue) 인스턴스 종료 대기 시간 (분)
      }
    }

    # 배포 방식 지정
    deployment_style = {
      deployment_type = "BLUE_GREEN" # 배포 방식: Blue/Green

      # WITH_TRAFFIC_CONTROL : 트래픽을 ALB 리스너 기반으로 Blue -> Green으로 전환하도록 CodeDeploy에 위임
      # WITHOUT_TRAFFIC_CONTROL : 트래픽 전환없이 ECS Service만 업데이트 (테스트 목적, 특수 상황)
      deployment_option = "WITH_TRAFFIC_CONTROL"
    }

    # ECS 정보
    ecs_service = {
      cluster_name = "search-ecs-cluster"
      service_name = "search-embed-ecs-service"
    }

    # 로드 밸런서 및 타겟 그룹 설정
    load_balancer_info = {
      target_group_pair_info = {
        prod_traffic_route = {
          listener_arns = "search-embed-alb-blue-listener"
        }
        test_traffic_route = {
          listener_arns = "search-embed-alb-green-listener"
        }
        target_group = [
          { name = "search-embed-alb-blue-tg" },
          { name = "search-embed-alb-green-tg" }
        ]
      }
    }
    env = "stg"
  }
}

# CodeDeploy 배포 구성 생성
codedeploy_deployment_config = {
  search-embed-api-codedeploy-deployment-config = {
    deployment_config_name = "search-embed-api-codedeploy-deployment-config" # CodeDeploy에서 사용할 배포 구성 이름
    compute_platform       = "ECS"                                           # 배포 대상 플랫폼(ECS, Lambda, Server 중 하나)

    traffic_routing_config = {
      # 트래픽 라우팅 전략(TimeBasedCanary, TimeBasedLinear, AllAtOnce)
      type = "TimeBasedCanary"

      # 배포 시 Canary 방식으로 트래픽을 점진적으로 전환하기 위한 설정
      time_based_canary = {
        interval   = 5  # 최초 배포 시 전환할 트래픽 비율 (%)
        percentage = 10 # 최초 전환 이후, 나머지 트래픽을 전환하기까지 기다릴 시간 (분)
      }
    }
  }
}

########################################
# ACM 설정
########################################
acm_certificate = {
  search-certificate = {
    mode                      = "create"       # create or import
    domain_name               = "*.ymkim.shop" # ACM 인증서를 발급할 도메인명
    subject_alternative_names = "ymkim.shop"   # 추가로 인증서에 포함시킬 도메인 목록
    dns_validate              = true           # ACM 인증서 발급 방법(DNS, EMAIL) 소유권 검증
    certificate_body          = null           # 인증서 본문
    private_key               = null           # 개인키
    certificate_chain         = null           # 인증서 체인
    env                       = "stg"          # 환경 변수
  },
  # search-certificate-internal = {
  #   mode                      = "import"                   # create or import
  #   domain_name               = "internal.ymkim.shop"      # ACM 인증서를 발급할 도메인명
  #   subject_alternative_names = null                       # 추가로 인증서에 포함시킬 도메인 목록
  #   dns_validate              = false                      # ACM 인증서 발급 방법(DNS, EMAIL) 소유권 검증
  #   certificate_body          = file("certs/internal.crt") # 인증서 본문
  #   private_key               = file("certs/internal.key") # 개인키
  #   certificate_chain         = file("certs/chain.crt")    # 인증서 체인
  #   env                       = "stg"                      # 환경 변수
  # }
}

########################################
# Route53 설정
########################################
route53_zone_settings = {
  search-certificate = {
    mode = "create"
    name = "ymkim.shop"
  },
  # search-certificate-internal = { # Route53 생성 안함
  #   mode = "import"
  #   name = "internal.ymkim.shop"
  # }
}

########################################
# 공통 태그 설정
########################################
tags = {
  project   = "search-recommand"
  service   = "search-recommand"
  teamTag   = "devops"
  managedBy = "terraform-admin"
  createdBy = "devops@example.com"
  env       = "stg"
}
