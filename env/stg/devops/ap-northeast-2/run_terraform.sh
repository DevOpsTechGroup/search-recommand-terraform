#!/bin/bash
terraform init
terraform refresh
terraform fmt -check
terraform validate
terraform plan
