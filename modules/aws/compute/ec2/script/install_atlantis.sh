#!/bin/bash
# 스크립트 오류 발생 시 즉시 스크립트 종료
set -e

##############################
# 1. 시스템 설정 및 기본 패키지 설치
##############################
echo -e "################################"
echo -e "1. 시스템 설정 및 기본 패키지 설치"
echo -e "################################"
# 호스트명 설정
sudo hostnamectl --static set-hostname Atlantis
echo

# alias 설정 및 bashrc 수정
echo 'alias vi=vim' | sudo tee -a /etc/profile

# 필수 패키지 설치
sudo yum update -y
sudo yum search docker -y
sudo yum install docker -y
sudo systemctl enable docker.service
sudo systemctl start docker.service
# sudo systemctl status docker.service --no-pager
sudo yum install -y yum-utils unzip jq tree zip curl wget --allowerasing

##############################
# 2. Terraform 설치
##############################
echo -e "################################"
echo -e "2. Terraform 설치"
echo -e "################################"
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum install -y terraform

# 설치 확인
terraform -version

##############################
# 3. AWS CLI v2 설치
##############################
echo -e "################################"
echo -e "3. AWS CLI v2 설치"
echo -e "################################"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws

# 설치 확인
aws --version

# 작업 디렉토리 설정
cd /home/ec2-user

# AWS 디렉토리 및 파일 생성
mkdir -p /home/ec2-user/.aws
touch /home/ec2-user/.aws/credentials
touch /home/ec2-user/.aws/config
chmod 700 /home/ec2-user/.aws
chmod 600 /home/ec2-user/.aws/credentials /home/ec2-user/.aws/config
sudo chown -R ec2-user:ec2-user /home/ec2-user/.aws

##############################
# 4. Dockerfile & docker image 생성
##############################
echo -e "################################"
echo -e "4. Dockerfile & docker image 생성"
echo -e "################################"
cat <<EOF > Dockerfile
# Atlantis Base Image 지정
FROM ghcr.io/runatlantis/atlantis:latest

# 기본 atlantis 사용자 대신 root 사용자로 변경
USER root

# AWS CLI 설치
RUN apk add --no-cache aws-cli

# AWS Credential 저장할 디렉토리 및 파일 생성
RUN mkdir /home/atlantis/.aws
RUN touch /home/atlantis/.aws/credentials
WORKDIR /home/atlantis

#RUN chown -R atlantis:atlantis /home/atlantis/.aws
EOF

# https://technote.kr/369
# 현재 사용자를 Docker 그룹에 추가
sudo usermod -aG docker ec2-user
#exec $SHELL -l

# Docker image 생성
sudo docker build -t atlantis .

# Docker Atlantis 실행
sudo docker run -itd \
-p 4141:4141 \
--name atlantis \
-v /home/ec2-user/.aws:/home/atlantis/.aws:ro \
atlantis server \
--automerge \
--autoplan-modules \
--gh-user=<github username> \
--gh-token=<github token> \
--repo-allowlist=github.com/<repo URL>