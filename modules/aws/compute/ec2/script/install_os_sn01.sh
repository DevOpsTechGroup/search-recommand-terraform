#!/bin/bash
set -e

################################
# 기본 환경 설정
################################
sudo hostnamectl set-hostname search-opensearch-test-sn01
sudo rm -f /etc/localtime
sudo ln -s /usr/share/zoneinfo/Asia/Seoul /etc/localtime

mkdir -p /home/ec2-user/apps
cd /home/ec2-user/apps

################################
# run_os.sh 스크립트 추가
################################
cat <<'EOF' > /home/ec2-user/apps/run_os.sh
#!/bin/bash

# OpenSearch 실행 경로
OPENSEARCH_PATH="/home/ec2-user/apps/opensearch/bin/opensearch"
JAVA_HOME="/usr/lib/jvm/java-11-amazon-corretto.aarch64"

# 로그 디렉토리 및 파일
LOG_DIR="/home/ec2-user/opensearch-logs"
LOG_FILE="$LOG_DIR/sn-node.log"
mkdir -p "$LOG_DIR"

# OpenSearch 시작 함수
start_opensearch() {
    echo "OpenSearch 싱글 노드 시작 중..."
    JAVA_HOME=$JAVA_HOME nohup $OPENSEARCH_PATH -d > "$LOG_FILE" 2>&1 &
}

# OpenSearch 종료 함수
stop_opensearch() {
    echo "OpenSearch 싱글 노드 종료 중..."
    pkill -f "opensearch"

    while pgrep -f "opensearch" > /dev/null; do
        echo "OpenSearch 종료 대기 중..."
        sleep 1
    done

    echo "OpenSearch 싱글 노드 종료 완료"
}

# OpenSearch 재시작 함수
restart_opensearch() {
    stop_opensearch
    echo "OpenSearch 싱글 노드 재시작 중..."
    start_opensearch
}

# 사용법 출력
usage() {
    echo "사용법: $0 [s | r | k]"
    echo "  s : OpenSearch 시작"
    echo "  r : OpenSearch 재시작"
    echo "  k : OpenSearch 종료"
    exit 1
}

# 파라미터 확인
if [ $# -eq 0 ]; then
    usage
fi

case "$1" in
    s)
        start_opensearch
        ;;
    r)
        restart_opensearch
        ;;
    k)
        stop_opensearch
        ;;
    *)
        usage
        ;;
esac
exit 0
EOF

chmod +x /home/ec2-user/apps/run_os.sh

################################
# .bashrc에 OpenSearch alias 추가
################################
echo "" >> /home/ec2-user/.bashrc
echo "# OpenSearch alias" >> /home/ec2-user/.bashrc
echo "alias odc='vi /home/ec2-user/apps/opensearch/config/opensearch.yml'" >> /home/ec2-user/.bashrc
echo "alias odcv='vi /home/ec2-user/apps/opensearch/config/jvm.options'" >> /home/ec2-user/.bashrc
# source는 user_data에서 의미 없음
# source ~/.bashrc

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

cd /home/ec2-user/apps
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
sudo swapoff -a

# 2. mmap 용량 확장
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
cat /proc/sys/vm/max_map_count

################################
# /etc/hosts 설정 (선택)
################################
sudo tee -a /etc/hosts > /dev/null <<EOF
172.21.10.200    os-za-sn01
EOF

################################
# opensearch.yml 생성 (Single Node 설정)
################################
cat <<'EOF' > /home/ec2-user/apps/opensearch/config/opensearch.yml
cluster.name: opensearch-test-cluster
node.name: os-za-sn01

node.roles: [master, data, ingest]

path.data: /home/ec2-user/apps-data
path.logs: /home/ec2-user/apps-log

network.host: 0.0.0.0
http.port: 9200
transport.tcp.port: 9300

discovery.seed_hosts: []

cluster.initial_cluster_manager_nodes:
  - os-za-sn01

plugins.security.disabled: true
EOF

################################
# jvm.options 수정 (Single Node 설정)
################################
cat <<'EOF' > /home/ec2-user/apps/opensearch/config/jvm.options
-Xms6g
-Xmx6g

11-:-XX:+UseG1GC
11-:-XX:G1ReservePercent=25
11-:-XX:InitiatingHeapOccupancyPercent=30

-Djava.io.tmpdir=${OPENSEARCH_TMPDIR}
-XX:+HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=data
-XX:ErrorFile=logs/hs_err_pid%p.log

9-:-Xlog:gc*,gc+age=trace,safepoint:file=logs/gc.log:utctime,pid,tags:filecount=32,filesize=64m

18-:-Djava.security.manager=allow
20-:--add-modules=jdk.incubator.vector
-Djava.util.concurrent.ForkJoinPool.common.threadFactory=org.opensearch.secure_sm.SecuredForkJoinWorkerThreadFactory
EOF

################################
# Opensearch dashboard 설치
################################
cd /home/ec2-user/apps

cat <<'EOF' > /home/ec2-user/apps/setup_os_db.sh
#!/bin/bash
set -e

OS_VERSION="2.18.0"
TAR_FILE_NAME="opensearch-dashboards-${OS_VERSION}-linux-arm64.tar.gz"
DOWNLOAD_URL="https://artifacts.opensearch.org/releases/bundle/opensearch-dashboards/${OS_VERSION}/${TAR_FILE_NAME}"

wget $DOWNLOAD_URL
tar -xvzf $TAR_FILE_NAME
rm -f opensearch-dashboards
ln -s "opensearch-dashboards-${OS_VERSION}" opensearch-dashboards

cat <<'EOCONF' > /home/ec2-user/apps/opensearch-dashboards/config/opensearch_dashboards.yml
server.host: "0.0.0.0"
opensearch.hosts: ["http://localhost:9200"]
EOCONF

cat <<'EODASH_SCRIPT' > /home/ec2-user/apps/run_os_db.sh
#!/bin/bash
LOG_DIR="/home/ec2-user/apps/opensearch-dashboards/logs"
mkdir -p $LOG_DIR

cd /home/ec2-user/apps/opensearch-dashboards

start_opensearch_db() {
  echo "OpenSearch Dashboards 실행 중..."
  nohup ./bin/opensearch-dashboards > $LOG_DIR/dashboards.log 2>&1 &
}

stop_opensearch_db() {
  echo "OpenSearch Dashboards 중지 중..."
  pkill -f "opensearch-dashboards"

  while pgrep -f "opensearch-dashboards" > /dev/null; do
    echo "종료 대기 중..."
    sleep 1
  done

  echo "OpenSearch Dashboards 중지 완료."
}

case "$1" in
  s)
    start_opensearch_db
    ;;
  k)
    stop_opensearch_db
    ;;
  *)
    echo "사용법: $0 [s|k]"
    echo "  s : 시작"
    echo "  k : 종료"
    exit 1
    ;;
esac

sleep 2
echo "실행 완료. 로그 파일 위치: $LOG_DIR/dashboards.log"
echo "접속 포트: 5601"
echo "로그 확인: tail -f $LOG_DIR/dashboards.log"
EODASH_SCRIPT

chmod +x /home/ec2-user/apps/run_os_db.sh
echo "OpenSearch Dashboards 설치 완료"
EOF

chmod +x /home/ec2-user/apps/setup_os_db.sh

################################
# 완료 메시지
################################
echo ""
echo "OpenSearch 싱글 노드 설치 완료"