#!/bin/bash
set -e

########################################
# 시스템 설정 및 기본 패키지 설치
########################################
sudo hostnamectl set-hostname search-opensearch-test-c03
sudo ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
sudo dnf update -y
sudo dnf install -y docker git vim unzip jq tree zip curl wget yum-utils --allowerasing
sudo systemctl enable --now docker
sudo usermod -aG docker ec2-user

################################
# run_os.sh 스크립트 추가
################################
cat <<'EOF' > run_os.sh
#!/bin/bash
# OpenSearch 실행 경로
COORDINATOR_PATH="/home/ec2-user/apps-c/opensearch-2.18.0/bin"
MASTER_PATH="/home/ec2-user/apps-m/opensearch-2.18.0/bin"

# JAVA_HOME
JAVA_HOME_PATH="/usr/lib/jvm/java-11-amazon-corretto.aarch64"

# 로그 디렉토리 설정
LOG_DIR="/home/ec2-user/opensearch-logs"
mkdir -p "$LOG_DIR"

# OpenSearch 시작 함수 (마스터 → 코디 순서)
start_opensearch() {
    echo "마스터 노드 시작 중..."
    cd "$MASTER_PATH"
    JAVA_HOME=$JAVA_HOME_PATH nohup ./opensearch -d > "$LOG_DIR/master.log" 2>&1 &
    sleep 10

    echo "코디네이터 노드 시작 중..."
    cd "$COORDINATOR_PATH"
    JAVA_HOME=$JAVA_HOME_PATH nohup ./opensearch -d > "$LOG_DIR/coordinator.log" 2>&1 &
}

# OpenSearch 종료 함수
stop_opensearch() {
    echo "OpenSearch 프로세스 종료 중..."
    pkill -f "opensearch"

    while pgrep -f "opensearch" > /dev/null; do
        echo "opensearch 종료 대기 중..."
        sleep 1
    done
    echo "모든 opensearch 프로세스 종료 완료"
}

# OpenSearch 재시작 함수
restart_opensearch() {
    stop_opensearch
    start_opensearch
}

# 사용법 안내
usage() {
    echo "사용법: $0 [s | r | k]"
    echo "  s : 시작"
    echo "  r : 재시작"
    echo "  k : 종료"
    exit 1
}

# 파라미터 처리
if [ $# -eq 0 ]; then
    usage
fi

case "$1" in
    s)
        echo "OpenSearch 시작 중..."
        start_opensearch
        ;;
    r)
        echo "OpenSearch 재시작 중..."
        restart_opensearch
        ;;
    k)
        echo "OpenSearch 종료 중..."
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
echo "alias occ='vi /home/ec2-user/apps-c/opensearch/config/opensearch.yml'" >> /home/ec2-user/.bashrc
echo "alias occv='vi /home/ec2-user/apps-c/opensearch/config/jvm.options'" >> /home/ec2-user/.bashrc
echo "alias ocm='vi /home/ec2-user/apps-m/opensearch/config/opensearch.yml'" >> /home/ec2-user/.bashrc
echo "alias ocmv='vi /home/ec2-user/apps-m/opensearch/config/jvm.options'" >> /home/ec2-user/.bashrc

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
172.21.10.200    os-za-m01
172.21.20.200    os-zb-m02
172.21.30.200    os-zc-m03
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
node.name: os-zc-c03

node.roles: []

path.data: /home/ec2-user/apps-c-data
path.logs: /home/ec2-user/apps-c-log

network.host: 0.0.0.0
http.port: 9200
transport.tcp.port: 9300

discovery.seed_hosts:
  - 172.21.10.200:9400 # master node
  - 172.21.20.200:9400 # master node
  - 172.21.30.200:9400 # master node

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
node.name: os-zc-m03

node.roles: [cluster_manager]

path.data: /home/ec2-user/apps-m-data
path.logs: /home/ec2-user/apps-m-log

network.host: 0.0.0.0
http.port: 9100
transport.tcp.port: 9400

discovery.seed_hosts:
  - 172.21.10.200:9400
  - 172.21.20.200:9400
  - 172.21.30.200:9400

cluster.initial_cluster_manager_nodes:
  - os-za-m01
  - os-zb-m02
  - os-zc-m03

plugins.security.disabled: true
EOF

################################
# JVM 공통 옵션 정의
################################
JVM_OPTIONS=$(cat <<'EOF'
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

-Xms1g
-Xmx1g

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
11-:-XX:+UseG1GC
11-:-XX:G1ReservePercent=25
11-:-XX:InitiatingHeapOccupancyPercent=30

## JVM temporary directory
-Djava.io.tmpdir=${OPENSEARCH_TMPDIR}

## heap dumps
-XX:+HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=data
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

## JDK 9+ GC logging
9-:-Xlog:gc*,gc+age=trace,safepoint:file=logs/gc.log:utctime,pid,tags:filecount=32,filesize=64m

# Explicitly allow security manager
18-:-Djava.security.manager=allow

# JDK 20+ Incubating Vector Module
20-:--add-modules=jdk.incubator.vector

# ForkJoinPool 설정
-Djava.util.concurrent.ForkJoinPool.common.threadFactory=org.opensearch.secure_sm.SecuredForkJoinWorkerThreadFactory
EOF
)

################################
# 공통 JVM 옵션 파일 생성
################################
echo "$JVM_OPTIONS" > /home/ec2-user/apps-c/opensearch/config/jvm.options
echo "$JVM_OPTIONS" > /home/ec2-user/apps-m/opensearch/config/jvm.options

echo "OpenSearch 설치 및 cordi/master 설정 완료"