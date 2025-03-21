#!/bin/bash
# BUCKET_NAME=$1
BUCKET_NAME="terraform-s3-ymkim-state"
if [[ -z "$BUCKET_NAME" ]]; then
  echo "버킷명이 존재하지 않습니다."
  exit 1;
fi

# AWS S3 버킷의 모든 객체를 재귀적으로 삭제
aws s3 rm s3://$BUCKET_NAME --recursive

# 버저닝 된 S3 버킷 삭제
aws s3api delete-bucket --bucket $BUCKET_NAME

# DynamoDB 테이블 LOCK 여부와 상관없이 삭제
# terraform destroy -auto-approve -lock=false