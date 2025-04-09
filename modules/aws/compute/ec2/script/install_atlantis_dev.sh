#!/bin/bash
set -xe

########################################
# 시스템 설정 및 기본 패키지 설치
########################################
GH_USER="<github username>"
GH_TOKEN="<github token>"
REPO_ALLOW_LIST="<github allow repo URL>"
ATLANTIS_PORT=<port>
CONTAINER_NAME="atlantis"
EC2_USER="ec2-user"
HOME_DIR="/home/${EC2_USER}"

sudo hostnamectl set-hostname atlantis

sudo dnf update -y
sudo dnf install -y \
docker git vim unzip jq tree zip curl wget yum-utils \
--allowerasing

# 도커 시작 및 부팅 시 자동 실행 설정
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
RUN apk add --no-cache aws-cli
EOF

sudo chown ${EC2_USER}:${EC2_USER} ${HOME_DIR}/Dockerfile

# ec2-user 권한으로 Docker 이미지 빌드
sudo -u ${EC2_USER} bash -c "
  cd ${HOME_DIR}
  docker build -t atlantis .
"

########################################
# Atlantis 컨테이너 실행
########################################

# 기존 컨테이너 제거
docker rm -f atlantis || true

sudo -u ${EC2_USER} bash -c "
  docker run -d \
    -p ${ATLANTIS_PORT}:${ATLANTIS_PORT} \
    --name ${CONTAINER_NAME} \
    atlantis server \
    --automerge \
    --autoplan-modules \
    --gh-user=${GH_USER} \
    --gh-token=${GH_TOKEN} \
    --repo-allowlist=${REPO_ALLOWLIST}
"