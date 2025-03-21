# search-recommand-terraform

## Overview

이 프로젝트는 Terraform을 사용하여 검색/추천 서비스의 인프라를 설정하고 관리하기 위한 리포지토리입니다.

## Tech Spec

> 최신 버전은 [Terraform Downloads](https://www.terraform.io/downloads.html)에서 받을 수 있습니다.

| Component                     | Version |
| ----------------------------- | ------- |
| Terraform                     | v1.9.7  |
| Provider (hashicorp/aws)      | v5.90.0 |
| Provider (hashicorp/random)   | v3.7.1  |
| Provider (hashicorp/template) | v2.2.0  |

## Usage

```shell
# move to working directory
cd env/dev/search-recommand/<region>
```

```shell
# exec terraform
# terraform init
# terraform refresh
# terraform fmt -check
# terraform validate
# terraform plan

chmod +x run_terraform.sh
./run_terraform.sh
```