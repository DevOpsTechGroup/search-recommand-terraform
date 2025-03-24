#!/bin/bash
################################
# 기본 셋팅
################################
# hostname 셋팅
sudo hostnamectl set-hostname search-recommand-bastion

# ec2 디렉토리 생성 후 해당 ec2 dir 이동
mkdir ec2 && cd ec2

################################
# Private EC2 접속 shell 생성
################################
cat <<"EOF"> conn_vector.sh
#!/bin/bash
SSH_KEY="/home/ec2-user/ec2/opensearch-ec2-key.pem"
TARGET_IP="172.21.50.253"
USER="ec2-user"
ssh -i $SSH_KEY -p 22 $USER@$TARGET_IP
EOF

# shell 권한 수정
chmod 700 conn_vector.sh

################################
# 필수 패키지 설치
################################
sudo yum update -y
sudo yum install -y tree telnet curl htop
sudo amazon-linux-extras install docker -y
sudo service docker start
sudo usermod -a -G docker ec2-user