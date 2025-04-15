#!/bin/bash
set -e

########################################
# 시스템 설정 및 기본 패키지 설치
########################################
sudo hostnamectl set-hostname search-opensearch-test-c02
sudo ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
sudo dnf update -y
sudo dnf install -y docker git vim unzip jq tree zip curl wget yum-utils --allowerasing
sudo systemctl enable --now docker
sudo usermod -aG docker ec2-user

################################
# 성능 및 안정성 설정
################################
# 1. 스왑 비활성화
# 이유: JVM 힙 메모리가 스왑 영역으로 밀려나면 성능 저하 및 GC 지연 가능성 있음
sudo swapoff -a

# 2. mmap 용량 확장
# 이유: OpenSearch는 많은 수의 memory-mapped files을 사용하므로 기본값(65530)으로는 부족
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
cat /proc/sys/vm/max_map_count

########################################
# /etc/hosts 수정
########################################
sudo tee -a /etc/hosts > /dev/null <<EOF
172.21.xx.xx    os-za-m01
172.21.xx.xx    os-zb-m02
172.21.xx.xx    os-zc-m03

172.21.xx.xx    os-za-c01
172.21.xx.xx    os-zb-c02
172.21.xx.xx    os-zc-c03
EOF

echo "Opensearch 환경 구성 시작..."

########################################
# 디렉토리 생성
########################################
mkdir -p /home/ec2-user/apps-c
mkdir -p /home/ec2-user/apps-m

########################################
# OpenSearch tar 다운로드 및 압축 해제
########################################
cd /home/ec2-user/apps-c
wget https://artifacts.opensearch.org/releases/bundle/opensearch/2.18.0/opensearch-2.18.0-linux-arm64.tar.gz
tar -xvzf opensearch-2.18.0-linux-arm64.tar.gz
ln -s opensearch-2.18.0 opensearch

cd /home/ec2-user/apps-m
cp /home/ec2-user/apps-c/opensearch-2.18.0-linux-arm64.tar.gz .
tar -xvzf opensearch-2.18.0-linux-arm64.tar.gz
ln -s opensearch-2.18.0 opensearch

########################################
# Java 설치
########################################
sudo yum install -y java-11-amazon-corretto
java --version

########################################
# cordi 노드용 opensearch.yml 작성
########################################
cat <<EOF > /home/ec2-user/apps-c/opensearch/config/opensearch.yml
cluster.name: opensearch-test-cluster
node.name: os-zb-c02

node.roles: []

path.data: /home/ec2-user/apps-c-data
path.logs: /home/ec2-user/apps-c-log

network.host: 0.0.0.0
http.port: 9200
transport.tcp.port: 9300

discovery.seed_hosts:
  - 172.21.xx.xx:9400
  - 172.21.xx.xx:9400
  - 172.21.xx.xx:9400

cluster.initial_cluster_manager_nodes:
  - os-za-m01
  - os-zb-m02
  - os-zc-m03

plugins.security.disabled: true
EOF

########################################
# master 노드용 opensearch.yml 작성
########################################
cat <<EOF > /home/ec2-user/apps-m/opensearch/config/opensearch.yml
cluster.name: opensearch-test-cluster
node.name: os-zb-m02

node.roles: [cluster_manager]

path.data: /home/ec2-user/apps-m-data
path.logs: /home/ec2-user/apps-m-log

network.host: 0.0.0.0
http.port: 9100
transport.tcp.port: 9400

discovery.seed_hosts:
  - 172.21.xx.xx:9400
  - 172.21.xx.xx:9400
  - 172.21.xx.xx:9400

cluster.initial_cluster_manager_nodes:
  - os-za-m01
  - os-zb-m02
  - os-zc-m03

plugins.security.disabled: true
EOF

echo "OpenSearch 설치 및 cordi/master 설정 완료"