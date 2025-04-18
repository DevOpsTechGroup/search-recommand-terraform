locals {
  # key가 search-opensearch로 시작하지 않는 경우만 필터링
  filtered_ec2_instance = {
    for key, value in var.ec2_instance : key => value
    if !startswith(key, "search-opensearch")
  }
}