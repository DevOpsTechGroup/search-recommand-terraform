#!/bin/bash
# Jenkins 베어메탈 설치 참고 URL
# - https://medium.com/@navidehbaghaifar/how-to-install-jenkins-on-an-ec2-with-terraform-d5e9ed3cdcd9

cd ~ && mkdir -p apps && cd apps

##############################
# 시스템 설정 및 기본 패키지 설치
##############################
echo -e "################################"
echo -e "# 시스템 설정 및 기본 패키지 설치"
echo -e "################################"
# 시스템 시간 설정
sudo ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime

# 호스트명 설정
sudo hostnamectl --static set-hostname search-jenkins-test-01
echo

##############################
# 필수 패키지 설치
##############################
echo -e "################################"
echo -e "# 필수 패키지 설치"
echo -e "################################"
sudo dnf update -y # 시스템 패키지를 모두 최신 버전으로 업그레이드

# 필요한 패키지 한 번에 설치
sudo dnf install docker -y
sudo dnf install java-17-amazon-corretto -y
sudo dnf install wget -y
sudo dnf install git -y
sudo dnf install curl -y

# Docker 설정
sudo systemctl start docker # Docker 데몬 수동으로 시작
sudo systemctl enable docker # 시스템 부팅 시 Docker 데몬 자동 시작
sudo usermod -aG docker ec2-user # ec2-user가 Docker 명령어를 sudo 없이 실행할 수 있도록 권한 부여
sudo usermod -aG docker jenkins
sudo yum install java-17-amazon-corretto -y
java -version
echo

##############################
# Jenkins 설치
##############################
# Jenkins 리포지토리 추가
# Amazon Linux, CentOS 기본 리포지토리에는 Jenkins가 없거나,
# 너무 오래된 버전이 존재할 수 있기에, Jenkins 공식 리포지토리를 추가

# yum+dnf 패키지 설치 시 -> /etc/yum.repos.d/*.repo -> 경로를 검색해서 설치한다
sudo wget -O /etc/yum.repos.d/jenkins.repo \
https://pkg.jenkins.io/redhat-stable/jenkins.repo

# 패키지 검증을 위해 Jenkins가 제공하는 공개키(GPG Key)를 시스템에 등록
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
echo

echo "Jenkins 설치 시작..."
sleep 5
sudo dnf install jenkins -y
sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo systemctl status jenkins
echo
echo "Jenkins 설치 완료..."