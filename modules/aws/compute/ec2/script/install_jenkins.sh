#!/bin/bash
# Jenkins 베어메탈 설치 참고 URL
# - https://medium.com/@navidehbaghaifar/how-to-install-jenkins-on-an-ec2-with-terraform-d5e9ed3cdcd9

##############################
# 1. 시스템 설정 및 기본 패키지 설치
##############################
echo -e "################################"
echo -e "1. 시스템 설정 및 기본 패키지 설치"
echo -e "################################"
# 호스트명 설정
sudo hostnamectl --static set-hostname Jenkins
echo

##############################
# 2. 필수 패키지 설치
##############################
echo -e "################################"
echo -e "2. 필수 패키지 설치"
echo -e "################################"
sudo dnf update -y # 패키지 매니저 업데이트
sudo dnf search docker -y # 설치 가능한 Docker 버전 확인
sudo dnf install docker -y # Docker 설치
sudo systemctl start docker # Docker 데몬 수동으로 시작
sudo systemctl enable docker # 시스템 부팅 시 Docker 데몬 자동 시작
sudo usermod -aG docker ec2-user # ec2-user가 Docker 명령어를 sudo 없이 실행할 수 있도록 권한 부여
echo

echo -e "################################"
echo -e "3. Jenkins 설치 및 컨테이너 환경 구성"
echo -e "################################"
# Docker Jenkins의 경우 2024년 10월 이후부터 Java 17 or 21을 요구하기에 jdk 17로 셋팅
# Jenkins에서는 LTS(Long-Term Support)와 Weekly 두 가지 릴리즈 버전을 가지고 있음
# - LTS: 안정성 + 장기적인 지원을 보장하는 버전
# - Weekly: 최신 기능과 개선 사항이 포함된 버전
# https://hub.docker.com/layers/jenkins/jenkins/lts-jdk17/images/sha256-d09e6172a0c88f41c56a7d98bbc1817aeb8d3086e70e8bd2b2640502ceb30f3b
sudo docker pull jenkins/jenkins:lts-jdk17

# Jenkins Docker container 실행
# TODO: 마운트의 경우 docker volume을 일단 사용, 추후 변경 관련 고민이 필요할 듯
sudo docker run -d \
-p 8080:8080 \
-p 50000:50000 \
--name jenkins \
--restart=on-failure \
-v jenkins_home:/var/jenkins_home \
jenkins/jenkins:lts-jdk17

# docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword