/*
  Terraform 상태 관리 state 파일을 S3에 올려두고 상태 관리 수행
  - Terraform backend란?
    - https://terraform101.inflearn.devopsart.dev/advanced/backend/
    - https://kschoi728.tistory.com/30
    - Terraform backend file은 state file을 어디에 저장하고 가져올지에 대한 설정
    - 기본적으로 로컬 스토리지에 저장하지만, 설정에 따라 s3, consul, etcd 등의 타입 설정 가능
  
  - Terraform backend 사용 목적?
    - Locking: 보통 terraform 코드는 혼자 작성하지 않으며 인프라를 변경하는건 민감한 작업
    이러한 부분을 방지하기 위해 원격 저장소를 사용하여 동시에 갖는 state 파일에 접근하는 것을 막는다
    이를 통해 의도치 않은 변경을 방지할 수 있다.

    - Backup: 로컬 스토리지에 state file을 저장하면 의도치 않은 유실이 발생할 수 있음
    하지만 원격지에 저장함으로써 state file의 유실을 막을 수 있음

  - !important
    - dynamodb_table은 미리 생성되어 있어야함
*/
# terraform {
#   backend "s3" {
#     bucket         = "terraform-s3-ymkim-state" # s3 버킷명
#     key            = "dev/terraform.tfstate"    # state 파일 s3 저장 경로
#     region         = "ap-northeast-2"           # s3 리전
#     encrypt        = true                       # terraform.state 파일 암호화 지정 여부
#     dynamodb_table = "tfstate-lock"             # DynamoDB 테이블명, DynamoDB 테이블을 사용한 잠금 기능(동시성 제어)
#   }
# }
