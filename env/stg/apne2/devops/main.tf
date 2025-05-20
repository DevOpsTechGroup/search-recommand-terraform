# env/stg/devops/ap-northeast-2/main.tf

module "security" {
  # INFO: 보안그룹의 경우 1개의 모듈에서 모두 생성 후 ID만 넘기는 방식으로 사용
  # 추가적으로, 보안 그룹의 ingress/egress rule은 생성되는 resource의 locals.tf에서 처리
  source = "../../../../modules/aws/security"

  # 보안그룹
  alb_security_group = var.alb_security_group
  ecs_security_group = var.ecs_security_group
  ec2_security_group = var.ec2_security_group

  # 네트워크 관련 설정
  vpc_id = module.network.vpc_id

  # 프로젝트 기본 설정
  tags = var.tags # 공통 태그

  depends_on = [
    module.network
  ]
}

module "iam" {
  source = "../../../../modules/aws/iam"

  # IAM 관련 설정
  iam_custom_role       = var.iam_custom_role
  iam_custom_policy     = var.iam_custom_policy
  iam_managed_policy    = var.iam_managed_policy
  iam_policy_attachment = var.iam_policy_attachment
  iam_instance_profile  = var.iam_instance_profile

  # 프로젝트 기본 설정
  tags = var.tags
}

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
  alb                   = var.alb                               # 생성을 원하는 ALB 관련 정보
  alb_listener          = var.alb_listener                      # 위에서 생성한 ALB Listener 관련 정보
  alb_listener_rule     = var.alb_listener_rule                 # ALB Listener Rule
  target_group          = var.target_group                      # ALB의 Target Group
  alb_security_group    = var.alb_security_group                # ALB 보안그룹 이름
  alb_security_group_id = module.security.alb_security_group_id # ALB 보안그룹 ID
  public_subnet_ids     = module.network.public_subnet_ids

  # 네트워크 관련 설정
  vpc_id = module.network.vpc_id

  # 프로젝트 기본 설정
  project_name       = var.project_name
  env                = var.env
  availability_zones = var.availability_zones
  tags               = var.tags

  depends_on = [
    module.network,
    module.iam,
    module.security
  ]
}

module "ecr" {
  source = "../../../../modules/aws/ecr"

  # ECR 관련 설정
  ecr_repository = var.ecr_repository

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
  ecs_task_role_arn      = module.iam.iam_role_arns["search-ecs-task-role"]      # security module의 output 변수 사용
  ecs_task_exec_role_arn = module.iam.iam_role_arns["search-ecs-task-exec-role"] # security module의 output 변수 사용
  ecs_security_group     = var.ecs_security_group                                # ECS Service 보안그룹 지정

  # ECS Service에서 ELB 연동 시 사용
  alb_tg_arn       = module.elb.alb_target_group_arn # loadbalancer module의 output 변수 사용
  alb_listener_arn = module.elb.alb_listener_arn     # loadbalancer module의 output 변수 사용

  ecs_security_group_id  = module.security.ecs_security_group_id  # ECS 보안그룹 ID
  ecs_security_group_arn = module.security.ecs_security_group_arn # ECS 보안그룹 ARN

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
    module.iam,     # IAM 모듈 참조
    module.security # security 보안그룹 모듈 참조
  ]
}

module "ec2" {
  source = "../../../../modules/aws/compute/ec2"

  # 네트워크 설정
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids  # VPC 퍼블릭 서브넷 목록
  private_subnet_ids = module.network.private_subnet_ids # VPC 프라이빗 서브넷 목록

  # EC2 설정
  ec2_instance          = var.ec2_instance                      # EC2 정보 전달
  ec2_security_group_id = module.security.ec2_security_group_id # EC2 보안그룹 ID
  iam_instance_profile  = module.iam.iam_instance_profile       # EC2 instance profile
  ec2_key_pair          = var.ec2_key_pair                      # EC2 key pair

  # 프로젝트 기본 설정
  env                = var.env
  tags               = var.tags
  availability_zones = var.availability_zones

  depends_on = [
    module.network, # network 모듈 참조
    module.iam,
    module.security
  ]
}

module "storage" {
  source = "../../../../modules/aws/storage"

  # S3 Bucket 관련 설정
  s3_bucket = var.s3_bucket

  # 프로젝트 기본 설정
  project_name = var.project_name
  env          = var.env
  tags         = var.tags
}

module "vpc_endpoint" {
  source = "../../../../modules/aws/vpc_endpoint"

  # 네트워크
  vpc_id                  = module.network.vpc_id
  vpc_endpoint_gateway    = var.vpc_endpoint_gateway
  vpc_endpoint_interface  = var.vpc_endpoint_interface
  private_route_table_ids = module.network.private_route_table_id
  security_group_ids      = module.security.all_security_group_id
  subnet_ids              = module.network.private_subnet_ids

  # 프로젝트 기본 설정
  project_name = var.project_name
  env          = var.env
  aws_region   = var.aws_region
  tags         = var.tags

  depends_on = [
    module.network,
    module.security
  ]
}

module "codedeploy" {
  source = "../../../../modules/aws/cicd/codedeploy"

  # CI/CD 관련 설정
  codedeploy_app               = var.codedeploy_app
  codedeploy_deployment_group  = var.codedeploy_deployment_group
  codedeploy_deployment_config = var.codedeploy_deployment_config

  # IAM 관련 설정
  service_role_arn = module.iam.iam_role_arns["search-codedeploy-service-role"]

  # 로드밸런서 관련 설정
  alb_listener_arn = module.elb.alb_listener_arn # 모든 ALB ARN 전달

  # 프로젝트 기본 설정
  project_name = var.project_name
  env          = var.env
  tags         = var.tags

  depends_on = [
    module.network,  # network 모듈 참조
    module.iam,      # IAM 모듈 참조
    module.security, # security 보안그룹 모듈 참조
    module.elb,      # load balancer 모듈 참조
    module.ecs       # ecs 모듈 참조
  ]
}

module "acm" {
  source = "../../../../modules/aws/acm"

  # ACM 관련 설정
  acm_certificate = var.acm_certificate

  # 프로젝트 기본 설정
  project_name = var.project_name
  env          = var.env
  tags         = var.tags
}

module "route53" {
  source = "../../../../modules/aws/route53"
}
