#!/bin/bash
set -xe  # 디버깅 + 실패 시 즉시 종료

########################################
# 1. 시스템 설정 및 기본 패키지 설치
########################################
hostnamectl --static set-hostname Atlantis

sudo dnf update -y
sudo dnf install -y docker git vim unzip jq tree zip curl wget yum-utils --allowerasing

sudo systemctl enable docker
sudo systemctl start docker

########################################
# 2. Terraform 설치
########################################
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo dnf install -y terraform --allowerasing
terraform -version

########################################
# 3. AWS CLI v2 설치
########################################
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws
aws --version

########################################
# 4. Dockerfile & Docker Image 생성 (in ec2-user 홈)
########################################
cat <<EOF > /home/ec2-user/Dockerfile
FROM ghcr.io/runatlantis/atlantis:latest
USER root
RUN apk add --no-cache aws-cli
EOF

cd /home/ec2-user
docker build -t atlantis .

########################################
# 5. Atlantis 컨테이너 실행 (IAM Role 사용)
########################################
docker run -d \
-p 4141:4141 \
--name atlantis \
atlantis server \
--automerge \
--autoplan-modules \
--gh-user=<github username> \
--gh-token=<github token> \
--repo-allowlist=<github repository url>