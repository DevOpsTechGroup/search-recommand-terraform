#!/bin/bash
set -xe

########################################
# 시스템 변수 셋팅
########################################
AWS_EC2_USER="ec2-user"
HOME_DIR="/home/${AWS_EC2_USER}"

# Github username from SSM
GH_USER=$(aws ssm get-parameter \
--name /search-recommand/stg/atlantis-github-username \
--query "Parameter.Value" \
--output text \
--region "ap-northeast-2")

# Github token from SSM
GH_TOKEN=$(aws ssm get-parameter \
--name /search-recommand/stg/atlantis-github-token \
--with-decryption \
--query "Parameter.Value" \
--output text \
--region "ap-northeast-2")

# Github repo url from SSM
REPO_ALLOW_LIST=$(aws ssm get-parameter \
--name /search-recommand/stg/atlantis-github-repo \
--query "Parameter.Value" \
--output text \
--region "ap-northeast-2")

# Atlantis port number
ATLANTIS_PORT=$(aws ssm get-parameter \
--name /search-recommand/stg/atlantis-port \
--query "Parameter.Value" \
--output text \
--region "ap-northeast-2")

# Atlantis infra cost token
ATLANTIS_INFRACOST_TOKEN=$(aws ssm get-parameter \
--name /search-recommand/stg/atlantis-infracost-token \
--with-decryption \
--query "Parameter.Value" \
--output text \
--region "ap-northeast-2")

CONTAINER_NAME="search-atlantis"

########################################
# 시스템 설정 및 기본 패키지 설치
########################################
sudo hostnamectl set-hostname search-atlantis
sudo rm /etc/localtime
sudo ln -s /usr/share/zoneinfo/Asia/Seoul /etc/localtime

sudo dnf update -y
sudo dnf install -y docker git vim unzip jq tree zip curl wget yum-utils --allowerasing
sudo systemctl enable --now docker

# ec2-user를 docker 그룹에 추가 (sudo 없이 실행 가능하도록)
sudo usermod -aG docker ec2-user

########################################
# Terraform 설치
########################################
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo dnf install -y terraform --allowerasing
terraform -version

########################################
# AWS CLI v2 설치
########################################
cd /tmp
curl -sS "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install --update
rm -rf awscliv2.zip aws
aws --version

########################################
# Dockerfile & Docker Image 생성
########################################
cat <<EOF | sudo tee /home/ec2-user/Dockerfile > /dev/null
FROM ghcr.io/runatlantis/atlantis:latest
USER root

# 기존에 깔려있는 terraform은 강제로 제거
RUN rm -f /usr/local/bin/terraform

# Terraform 1.9.5 설치 전 디렉토리 생성 및 다운로드, 설치 진행
RUN mkdir -p /root/.atlantis/bin && \
    curl -Lo /tmp/terraform.zip https://releases.hashicorp.com/terraform/1.9.5/terraform_1.9.5_linux_amd64.zip && \
    unzip -o /tmp/terraform.zip -d /root/.atlantis/bin/ && \
    mv /root/.atlantis/bin/terraform /root/.atlantis/bin/terraform1.9.5 && \
    chmod +x /root/.atlantis/bin/terraform1.9.5 && \
    rm /tmp/terraform.zip

# 새 버전의 Terraform으로 심볼릭 링크 생성
RUN ln -s /root/.atlantis/bin/terraform1.9.5 /usr/bin/terraform

RUN apk add --no-cache aws-cli
EOF

sudo chown ${AWS_EC2_USER}:${AWS_EC2_USER} ${HOME_DIR}/Dockerfile

# ec2-user 권한으로 Docker 이미지 빌드
BUILD_DOCKER=$(cat <<EOF
cd ${HOME_DIR} &&
docker build -t atlantis .
EOF
)

sudo -u "${AWS_EC2_USER}" bash -c "$BUILD_DOCKER"

########################################
# Atlantis 컨테이너 실행
########################################
# ECS Agenct 비활성화 -> Container 구동 오류 발생
sudo systemctl stop ecs
sudo systemctl disable ecs

# https://www.runatlantis.io/docs/server-side-repo-config.html
# 기존 Atlantis 컨테이너 제거
docker rm -f $CONTAINER_NAME || true

# Atlantis Container 실행
# --automerge: true -> Atlantis Auto Merge 옵션
# => 위 옵션은 일단 제거 해두었음
RUN_DOCKER=$(cat <<EOF
docker run -d \
  -p ${ATLANTIS_PORT}:${ATLANTIS_PORT} \
  --name ${CONTAINER_NAME} \
  -e ATLANTIS_INFRACOST_TOKEN=${ATLANTIS_INFRACOST_TOKEN} \
  infracost/infracost-atlantis:latest server \
  --gh-user=${GH_USER} \
  --gh-token=${GH_TOKEN} \
  --repo-allowlist=${REPO_ALLOW_LIST} \
  --repo-config-json='
    {
      "repos": [
        {
          "id": "/.*/",
          "allowed_overrides": ["apply_requirements", "workflow", "delete_source_branch_on_merge"],
          "allow_custom_workflows": true,
          "workflow": "atlantis-infracost"
        }
      ],
      "workflows": {
        "atlantis-infracost": {
          "plan": {
            "steps": [
              "init",
              "plan",
              {
                "env": {
                  "name": "INFRACOST_API_KEY",
                  "value": "'"${ATLANTIS_INFRACOST_TOKEN}"'"
                }
              },
              {
                "run": "/home/atlantis/infracost_atlantis_diff.sh"
              }
            ]
          }
        }
      }
    }
  '
EOF
)

sudo -u "${AWS_EC2_USER}" bash -c "$RUN_DOCKER"