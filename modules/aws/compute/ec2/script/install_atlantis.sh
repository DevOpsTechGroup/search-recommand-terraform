#!/bin/bash
set -xe

########################################
# 시스템 변수 셋팅
########################################
AWS_EC2_USER="ec2-user"
HOME_DIR="/home/${AWS_EC2_USER}"

GH_USER=$(aws ssm get-parameter \
  --name /search-recommand/stg/atlantis-github-username \
  --query "Parameter.Value" \
  --output text \
  --region "ap-northeast-2")

GH_TOKEN=$(aws ssm get-parameter \
  --name /search-recommand/stg/atlantis-github-token \
  --with-decryption \
  --query "Parameter.Value" \
  --output text \
  --region "ap-northeast-2")

REPO_ALLOW_LIST=$(aws ssm get-parameter \
  --name /search-recommand/stg/atlantis-github-repo \
  --query "Parameter.Value" \
  --output text \
  --region "ap-northeast-2")

ATLANTIS_PORT=$(aws ssm get-parameter \
  --name /search-recommand/stg/atlantis-port \
  --query "Parameter.Value" \
  --output text \
  --region "ap-northeast-2")

CONTAINER_NAME="search-atlantis"

########################################
# 시스템 설정 및 기본 패키지 설치
########################################
sudo hostnamectl set-hostname search-atlantis
sudo ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
sudo dnf update -y
sudo dnf install -y docker git vim unzip jq tree zip curl wget yum-utils --allowerasing
sudo systemctl enable --now docker
sudo usermod -aG docker ${AWS_EC2_USER}

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
# Dockerfile & 이미지 빌드
########################################
cat <<EOF | sudo tee ${HOME_DIR}/Dockerfile > /dev/null
FROM ghcr.io/runatlantis/atlantis:latest
USER root
RUN rm -f /usr/local/bin/terraform
RUN mkdir -p /root/.atlantis/bin && \
    curl -Lo /tmp/terraform.zip https://releases.hashicorp.com/terraform/1.9.5/terraform_1.9.5_linux_amd64.zip && \
    unzip -o /tmp/terraform.zip -d /root/.atlantis/bin/ && \
    mv /root/.atlantis/bin/terraform /root/.atlantis/bin/terraform1.9.5 && \
    chmod +x /root/.atlantis/bin/terraform1.9.5 && \
    rm /tmp/terraform.zip
RUN ln -s /root/.atlantis/bin/terraform1.9.5 /usr/bin/terraform
RUN apk add --no-cache aws-cli
EOF

sudo chown ${AWS_EC2_USER}:${AWS_EC2_USER} ${HOME_DIR}/Dockerfile

sudo -u ${AWS_EC2_USER} bash -c "
  cd ${HOME_DIR} && docker build -t atlantis .
"

########################################
# Atlantis 서버 실행
########################################
# ECS Agent 충돌 방지
sudo systemctl stop ecs || true
sudo systemctl disable ecs || true

# Atlantis 설정 디렉토리
mkdir -p ${HOME_DIR}/atlantis-config
cat <<EOF | sudo tee ${HOME_DIR}/atlantis-config/config.yaml > /dev/null
repos:
  - id: /.*/
    allowed_overrides: [workflow, plan_requirements, apply_requirements, delete_source_branch_on_merge]
    allow_custom_workflows: true
EOF
sudo chown -R ${AWS_EC2_USER}:${AWS_EC2_USER} ${HOME_DIR}/atlantis-config

# 데이터 디렉토리
mkdir -p ${HOME_DIR}/atlantis-data
sudo chown -R ${AWS_EC2_USER}:${AWS_EC2_USER} ${HOME_DIR}/atlantis-data

# 기존 컨테이너 제거
docker rm -f ${CONTAINER_NAME} || true

# Atlantis 컨테이너 실행
RUN_DOCKER=$(cat <<EOF
docker run -d \
  -p ${ATLANTIS_PORT}:${ATLANTIS_PORT} \
  --name ${CONTAINER_NAME} \
  -v ${HOME_DIR}/atlantis-config/config.yaml:/home/atlantis/repos.yaml \
  -e ATLANTIS_REPO_CONFIG=/home/atlantis/repos.yaml \
  atlantis server \
  --autoplan-modules \
  --gh-user=${GH_USER} \
  --gh-token=${GH_TOKEN} \
  --repo-allowlist=${REPO_ALLOW_LIST}
EOF
)

sudo -u ${AWS_EC2_USER} bash -c "$RUN_DOCKER"