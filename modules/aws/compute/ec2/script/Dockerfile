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

################################################
# https://www.easydeploy.io/blog/install-atlantis-docker-container-in-amazon-linux-integrate/#
# exec docker command
################################################
# $ sudo usermod -a -G docker $USER
# $ docker build -t atlantis .
# $ docker run -itd -p 4141:4141 --name atlantis atlantis server --automerge --autoplan-modules --gh-user=<github-account-username> --gh-token=<github-usr-access-token> --repo-allowlist=<list of allowed repos
# $ docker ps
# $ docker exec -it atlantis /bin/sh
################################################