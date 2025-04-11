FROM ghcr.io/runatlantis/atlantis:latest
USER root

#RUN rm -f /usr/bin/terraform
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