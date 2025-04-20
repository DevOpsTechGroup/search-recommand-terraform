#!/bin/bash
################################
# 기본 셋팅
################################
sudo hostnamectl set-hostname opensearch
sudo rm /etc/localtime
sudo ln -s /usr/share/zoneinfo/Asia/Seoul /etc/localtime

################################
# 필수 패키지 설치
################################
sudo yum install -y tree telnet curl htop
sudo dnf update -y
sudo dnf search docker -y
sudo dnf install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user