#!/bin/bash
set -e

################################
# 기본 환경 설정
################################
sudo hostnamectl set-hostname search-opensearch-test-d02
sudo rm -f /etc/localtime
sudo ln -s /usr/share/zoneinfo/Asia/Seoul /etc/localtime

mkdir -p /home/ec2-user/apps-d
cd /home/ec2-user/apps-d

################################
# run_os.sh 스크립트 추가
################################
cat <<'EOF' > run_os.sh
#!/bin/bash

# OpenSearch 실행 경로
OPENSEARCH_PATH="/home/ec2-user/apps-d/opensearch/bin/opensearch"
JAVA_HOME="/usr/lib/jvm/java-11-amazon-corretto.aarch64"

# 로그 디렉토리 및 파일
LOG_DIR="/home/ec2-user/opensearch-logs"
LOG_FILE="$LOG_DIR/data-node.log"
mkdir -p "$LOG_DIR"

# OpenSearch 시작 함수
start_opensearch() {
    echo "OpenSearch 데이터 노드 시작 중..."
    JAVA_HOME=$JAVA_HOME nohup $OPENSEARCH_PATH -d > "$LOG_FILE" 2>&1 &
}

# OpenSearch 종료 함수
stop_opensearch() {
    echo "OpenSearch 데이터 노드 종료 중..."
    pkill -f "opensearch"

    while pgrep -f "opensearch" > /dev/null; do
        echo "OpenSearch 종료 대기 중..."
        sleep 1
    done

    echo "OpenSearch 데이터 노드 종료 완료"
}

# OpenSearch 재시작 함수
restart_opensearch() {
    stop_opensearch
    echo "OpenSearch 데이터 노드 재시작 중..."
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
chmod +x run_os.sh

################################
# .bashrc에 OpenSearch alias 추가
################################
echo "" >> /home/ec2-user/.bashrc
echo "# OpenSearch alias" >> /home/ec2-user/.bashrc
echo "alias odc='vi /home/ec2-user/apps-d/opensearch/config/opensearch.yml'" >> /home/ec2-user/.bashrc
echo "alias odcv='vi /home/ec2-user/apps-d/opensearch/config/jvm.options'" >> /home/ec2-user/.bashrc
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
172.21.10.200    os-za-m01
172.21.20.200    os-zb-m02
172.21.30.200    os-zc-m03
EOF

################################
# opensearch.yml 생성 (Data Node 설정)
################################
cat <<EOF > /home/ec2-user/apps-d/opensearch/config/opensearch.yml
cluster.name: opensearch-test-cluster
node.name: os-zb-d02

node.roles: [data]

path.data: /home/ec2-user/apps-d-data
path.logs: /home/ec2-user/apps-d-log

network.host: 0.0.0.0
http.port: 9200
transport.tcp.port: 9300

discovery.seed_hosts:
  - 172.21.10.200:9400 # master node
  - 172.21.20.200:9400 # master node
  - 172.21.30.200:9400 # master node

cluster.initial_cluster_manager_nodes:
  - os-za-m01 # master node
  - os-zb-m02 # master node
  - os-zc-m03 # master node

plugins.security.disabled: true
EOF

################################
# jvm.options 수정 (Data Node 설정)
################################
cat <<EOF > /home/ec2-user/apps-d/opensearch/config/jvm.options
## JVM configuration

################################################################
## IMPORTANT: JVM heap size
################################################################
##
## You should always set the min and max JVM heap
## size to the same value. For example, to set
## the heap to 4 GB, set:
##
## -Xms4g
## -Xmx4g
##
## See https://opensearch.org/docs/opensearch/install/important-settings/
## for more information
##
################################################################

# Xms represents the initial size of total heap space
# Xmx represents the maximum size of total heap space

-Xms6g
-Xmx6g

################################################################
## Expert settings
################################################################
##
## All settings below this section are considered
## expert settings. Don't tamper with them unless
## you understand what you are doing
##
################################################################

## GC configuration
8-10:-XX:+UseConcMarkSweepGC
8-10:-XX:CMSInitiatingOccupancyFraction=75
8-10:-XX:+UseCMSInitiatingOccupancyOnly

## G1GC Configuration
# NOTE: G1GC is the default GC for all JDKs 11 and newer
11-:-XX:+UseG1GC
# See https://github.com/elastic/elasticsearch/pull/46169 for the history
# behind these settings, but the tl;dr is that default values can lead
# to situations where heap usage grows enough to trigger a circuit breaker
# before GC kicks in.
11-:-XX:G1ReservePercent=25
11-:-XX:InitiatingHeapOccupancyPercent=30

## JVM temporary directory
-Djava.io.tmpdir=${OPENSEARCH_TMPDIR}

## heap dumps

# generate a heap dump when an allocation from the Java heap fails
# heap dumps are created in the working directory of the JVM
-XX:+HeapDumpOnOutOfMemoryError

# specify an alternative path for heap dumps; ensure the directory exists and
# has sufficient space
-XX:HeapDumpPath=data

# specify an alternative path for JVM fatal error logs
-XX:ErrorFile=logs/hs_err_pid%p.log

## JDK 8 GC logging
8:-XX:+PrintGCDetails
8:-XX:+PrintGCDateStamps
8:-XX:+PrintTenuringDistribution
8:-XX:+PrintGCApplicationStoppedTime
8:-Xloggc:logs/gc.log
8:-XX:+UseGCLogFileRotation
8:-XX:NumberOfGCLogFiles=32
8:-XX:GCLogFileSize=64m

# JDK 9+ GC logging
9-:-Xlog:gc*,gc+age=trace,safepoint:file=logs/gc.log:utctime,pid,tags:filecount=32,filesize=64m

# Explicitly allow security manager (https://bugs.openjdk.java.net/browse/JDK-8270380)
18-:-Djava.security.manager=allow

# JDK 20+ Incubating Vector Module for SIMD optimizations;
# disabling may reduce performance on vector optimized lucene
20-:--add-modules=jdk.incubator.vector

# HDFS ForkJoinPool.common() support by SecurityManager
-Djava.util.concurrent.ForkJoinPool.common.threadFactory=org.opensearch.secure_sm.SecuredForkJoinWorkerThreadFactory
EOF

################################
# 완료 메시지
################################
echo ""
echo "OpenSearch Data 노드 설치 완료"