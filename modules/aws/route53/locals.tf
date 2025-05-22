/*
  domain_validation_options = {
    + search-certificate = [
        + {
            + domain_name           = "*.ymkim.shop"
            + resource_record_name  = (known after apply)
            + resource_record_type  = (known after apply)
            + resource_record_value = (known after apply)
          },
        + {
            + domain_name           = "ymkim.shop"
            + resource_record_name  = (known after apply)
            + resource_record_type  = (known after apply)
            + resource_record_value = (known after apply)
          },
      ]
  }

  route53_zone_settings = {
    search-certificate = {
      mode = "create"
      name = "ymkim.shop"
    },
  }

  route53_record_settings = {
    search-certificate = {
      mode            = "create"
      ttl             = 300
      allow_overwrite = true
    }
  }
}
*/

locals {
  acm_record_settings = {
    # TODO: domain_validation_options + route53_record_settings 옵션을 합쳐서 main.tf에서 레코드 생성
    # 대신, locals에서 중첩 for를 사용해서 데이터를 가공한 후 넘겨줘야 함. 아이패드에 그리면서 for문
    # 구조에 대해 생각을 해보고 진행 할것
  }
}
