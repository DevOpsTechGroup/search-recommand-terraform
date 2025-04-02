# env/stg/devops/ap-northeast-2/main.tf

module "network" {
  source = "../../../../modules/aws/network"

  vpc_cidr             = var.vpc_cidr             # IPV4 CIDR Block(172.22.0.0/16)
  enable_dns_support   = var.enable_dns_support   # DNS Hostname 사용 옵션, 기본 false(VPC 내 리소스가 AWS DNS 주소 사용 가능)
  enable_dns_hostnames = var.enable_dns_hostnames # DNS Hostname 사용 옵션, 기본 true(VPC 내 DNS 호스트 이름 사용)
  public_subnets_cidr  = var.public_subnets_cidr  # 퍼블릭 서브넷 목록(172.x.x.x/24, 172.x.x.x/24)
  private_subnets_cidr = var.private_subnets_cidr # 프라이빗 서브넷 목록(172.x.x.x/24, 172.x.x.x/24)
  availability_zones   = var.availability_zones   # 가용영역

  # 프로젝트 기본 설정
  project_name = var.project_name # 프로젝트명
  env          = var.env          # 개발 환경 변수
  tags         = var.tags         # 공통 태그
}

module "elb" {
  source = "../../../../modules/aws/elb"

  # 로드밸런서 관련 설정
  alb                = var.alb                # 생성을 원하는 ALB 관련 정보
  alb_listener       = var.alb_listener       # 위에서 생성한 ALB Listener 관련 정보
  alb_listener_rule  = var.alb_listener_rule  # ALB Listener Rule
  target_group       = var.target_group       # ALB의 Target Group
  alb_security_group = var.alb_security_group # ALB 보안그룹 이름
  public_subnet_ids  = module.network.public_subnet_ids

  # ECS 관련 설정
  ecs_security_group_id = module.ecs.ecs_security_group

  # 프로젝트 기본 설정
  project_name       = var.project_name
  env                = var.env
  availability_zones = var.availability_zones
  tags               = var.tags
  vpc_id             = module.network.vpc_id

  depends_on = [
    module.network
  ]
}

module "ecr" {
  source = "../../../../modules/aws/ecr"

  # ECR 관련 설정
  ecr_repository = var.ecr_repository

  # 프로젝트 기본 설정
  tags = var.tags
}

module "security" {
  source = "../../../../modules/aws/security"

  # IAM 관련 설정
  iam_custom_role       = var.iam_custom_role
  iam_custom_policy     = var.iam_custom_policy
  iam_managed_policy    = var.iam_managed_policy
  iam_policy_attachment = var.iam_policy_attachment

  # ECS IAM 관련 설정
  ecs_task_role               = var.ecs_task_role
  ecs_task_role_policy        = var.ecs_task_role_policy
  ecs_task_exec_role          = var.ecs_task_exec_role
  ecs_task_exec_role_policy   = var.ecs_task_exec_role_policy
  ecs_auto_scaling_role       = var.ecs_auto_scaling_role
  ecs_auto_scaling_policy_arn = var.ecs_auto_scaling_policy_arn

  # 프로젝트 기본 설정
  tags = var.tags
}

module "ecs" {
  source = "../../../../modules/aws/compute/ecs"

  # 네트워크 설정
  vpc_id               = module.network.vpc_id
  public_subnets_cidr  = var.public_subnets_cidr
  private_subnets_cidr = var.private_subnets_cidr
  public_subnet_ids    = module.network.public_subnet_ids  # Network의 output 변수 사용
  private_subnet_ids   = module.network.private_subnet_ids # Network의 output 변수 사용

  # ECS 관련 설정
  ecs_cluster                      = var.ecs_cluster                      # ECS Cluster 설정
  ecs_task_definitions             = var.ecs_task_definitions             # ECS Task 설정
  ecs_service                      = var.ecs_service                      # ECS Service 설정
  ecs_appautoscaling_target        = var.ecs_appautoscaling_target        # ECS Automoscaling target
  ecs_appautoscaling_target_policy = var.ecs_appautoscaling_target_policy # ECS Automatic scaling Policy
  ecs_cpu_scale_out_alert          = var.ecs_cpu_scale_out_alert          # ECS AutoScaling Alert

  # ECS IAM 권한 설정
  ecs_task_role_arn           = module.security.iam_resources["ecs-task-role-arn"]      # security module의 output 변수 사용
  ecs_task_exec_role_arn      = module.security.iam_resources["ecs-task-exec-role-arn"] # security module의 output 변수 사용
  ecs_security_group          = var.ecs_security_group                                  # ECS Service 보안그룹 지정
  ecs_container_image_version = var.ecs_container_image_version                         # ECS Container Image 버전

  # ECS Service에서 ELB 연동 시 사용
  alb_tg_arn       = module.elb.alb_target_group_arn # loadbalancer module의 output 변수 사용
  alb_listener_arn = module.elb.alb_listener_arn     # loadbalancer module의 output 변수 사용

  # TODO: 현재는 ALB 보안그룹을 1개만 받고 있는데, N개의 ALB 보안그룹 받을 수 있게 수정 필요
  alb_security_group_id = module.elb.alb_security_group_id # ECS에서 사용하는 ALB 보안 그룹 ID

  # 프로젝트 기본 설정
  project_name       = var.project_name
  availability_zones = var.availability_zones
  aws_region         = var.aws_region
  aws_account        = var.aws_account
  env                = var.env
  tags               = var.tags

  # 아래 모듈 리소스 생성 후, ecs 생성 가능
  depends_on = [
    module.network, # network 모듈 참조
    module.elb,     # load balancer 모듈 참조
    module.security # security 모듈 참조
  ]
}

module "ec2" {
  source = "../../../../modules/aws/compute/ec2"

  # 네트워크 설정
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids  # VPC 퍼블릭 서브넷 목록
  private_subnet_ids = module.network.private_subnet_ids # VPC 프라이빗 서브넷 목록

  # EC2 설정
  ec2_security_group               = var.ec2_security_group               # 보안그룹 정보 전달
  ec2_security_group_ingress_rules = var.ec2_security_group_ingress_rules # 보안그룹 규칙 정보 전달
  ec2_security_group_egress_rules  = var.ec2_security_group_egress_rules  # 보안그룹 규칙 정보 전달
  ec2_instance                     = var.ec2_instance                     # EC2 정보 전달

  # 프로젝트 기본 설정
  env                = var.env
  tags               = var.tags
  availability_zones = var.availability_zones

  depends_on = [
    module.network # network 모듈 참조
  ]
}

module "storage" {
  source = "../../../../modules/aws/storage"

  # S3 Bucket 관련 설정
  s3_bucket = var.s3_bucket

  # Dynamo DB Table 관련 설정
  dynamodb_table = var.dynamodb_table

  # 프로젝트 기본 설정
  project_name = var.project_name
  env          = var.env
  tags         = var.tags
}
