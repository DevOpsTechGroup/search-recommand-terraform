#!/bin/bash

################################
# 기본 셋팅
################################
sudo rm -f /etc/localtime
sudo ln -s /usr/share/zoneinfo/Asia/Seoul /etc/localtime
mkdir -p /home/ec2-user/apps
cd /home/ec2-user/apps

################################
# 필수 패키지 설치
################################
sudo dnf update -y
sudo dnf install -y tree telnet curl htop
sudo dnf install -y docker || echo "docker already installed"
sudo dnf install -y java-17-amazon-corretto
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

################################
# OpenSearch 설치
################################
OPENSEARCH_VERSION="2.18.0"
OPENSEARCH_TAR="opensearch-${OPENSEARCH_VERSION}-linux-arm64.tar.gz"
OPENSEARCH_DIR="opensearch-${OPENSEARCH_VERSION}"

# 파일 다운로드
curl -O "https://artifacts.opensearch.org/releases/bundle/opensearch/${OPENSEARCH_VERSION}/${OPENSEARCH_TAR}"

# 압축 해제
if [ -f "${OPENSEARCH_TAR}" ]; then
  tar -xvf "${OPENSEARCH_TAR}"
else
  echo "[ERROR] OpenSearch tar.gz 파일이 존재하지 않습니다."
  exit 1
fi

# 심볼릭 링크 정리 후 생성
rm -f opensearch
ln -s "${OPENSEARCH_DIR}" opensearch

# 디렉터리 이동
cd opensearch || { echo "[ERROR] opensearch 디렉토리로 이동 실패"; exit 1; }

################################
# 성능 및 시스템 설정
################################
# 스왑 비활성화
sudo swapoff -a

# 메모리 맵 수 증가
echo "vm.max_map_count=262144" | sudo tee /etc/sysctl.conf
sudo sysctl -p
cat /proc/sys/vm/max_map_count

################################
# 이후 설정은 수동 또는 스크립트 분리
################################
echo ""
echo "✅ OpenSearch 다운로드 및 기본 시스템 설정 완료"
echo "👉 config/opensearch.yml 과 jvm.options 파일 수동 편집 필요"
