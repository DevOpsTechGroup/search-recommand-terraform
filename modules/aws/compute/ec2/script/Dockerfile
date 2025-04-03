# Atlantis Base Image 지정
FROM ghcr.io/runatlantis/atlantis:latest

# 기본 atlantis 사용자 대신 root 사용자로 변경
USER root

# AWS CLI 설치
RUN apk add --no-cache aws-cli

# AWS Credential 저장할 디렉토리 및 파일 생성
RUN mkdir /home/atlantis/.aws
RUN touch /home/atlantis/.aws/credentials

# RUN chown atlantis.atlantis /home/atlantis/ -R