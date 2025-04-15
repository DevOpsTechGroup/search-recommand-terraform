#!/bin/bash
set -e

################################
# 기본 환경 설정
################################
sudo hostnamectl set-hostname search-opensearch-test-d01
sudo rm -f /etc/localtime
sudo ln -s /usr/share/zoneinfo/Asia/Seoul /etc/localtime

mkdir -p /home/ec2-user/apps-d
cd /home/ec2-user/apps-d

################################
# 필수 패키지 설치
################################
sudo dnf update -y
sudo dnf install -y tree telnet curl htop wget jq unzip git vim yum-utils --allowerasing
sudo dnf install -y docker || echo "docker already installed"
sudo dnf install -y java-11-amazon-corretto
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

################################
# OpenSearch 다운로드 및 설치
################################
OPENSEARCH_VERSION="2.18.0"
OPENSEARCH_TAR="opensearch-${OPENSEARCH_VERSION}-linux-arm64.tar.gz"
OPENSEARCH_DIR="opensearch-${OPENSEARCH_VERSION}"

cd /home/ec2-user/apps-d
curl -O "https://artifacts.opensearch.org/releases/bundle/opensearch/${OPENSEARCH_VERSION}/${OPENSEARCH_TAR}"

if [ -f "${OPENSEARCH_TAR}" ]; then
  tar -xvf "${OPENSEARCH_TAR}"
else
  echo "[ERROR] OpenSearch tar.gz 파일이 존재하지 않습니다."
  exit 1
fi

rm -f opensearch
ln -s "${OPENSEARCH_DIR}" opensearch
cd opensearch || { echo "[ERROR] opensearch 디렉토리로 이동 실패"; exit 1; }

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

################################
# /etc/hosts 설정 (선택)
################################
sudo tee -a /etc/hosts > /dev/null <<EOF
172.21.x.x    os-za-m01
172.21.x.x    os-zb-m02
172.21.x.x    os-zc-m03

172.21.x.x    os-za-d01
172.21.x.x    os-zb-d02
172.21.x.x    os-zc-d03
EOF

################################
# opensearch.yml 생성 (Data Node 설정)
################################
cat <<EOF > /home/ec2-user/apps-d/opensearch/config/opensearch.yml
cluster.name: opensearch-test-cluster
node.name: os-za-d01

node.roles: [data]

path.data: /home/ec2-user/apps-d-data
path.logs: /home/ec2-user/apps-d-log

network.host: 0.0.0.0
http.port: 9200
transport.tcp.port: 9300

discovery.seed_hosts:
  - 172.21.x.x:9400 # master node
  - 172.21.x.x:9400 # master node
  - 172.21.x.x:9400 # master node

cluster.initial_cluster_manager_nodes:
  - os-za-m01 # master node
  - os-zb-m02 # master node
  - os-zc-m03 # master node

plugins.security.disabled: true
EOF

################################
# 완료 메시지
################################
echo ""
echo "OpenSearch Data 노드 설치 완료"