locals {
  # TODO: 분석 필요
  acm_validation_records = merge([
    for cert_key, cert in aws_acm_certificate.create_cert : {
      for dvo in cert.domain_validation_options :
      "${cert_key}-${dvo.domain_name}" => {
        zone   = cert_key
        name   = dvo.resource_record_name
        type   = dvo.resource_record_type
        record = dvo.resource_record_value
      }
    }
  ]...)
}

/*
[
  {
    search-cerfificate-domain-1 = {
      ...
    },
    search-cerfificate-domain-2 = {
      ...
    },
  },
  {
    search-cerfificate-internal-domain-1 = {
      ...
    },
    search-cerfificate-internal-domain-2 = {
      ...
    },
  },
]

search-cerfificate = {
  ...
  domain_validation_options = [
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
},
search-certificate-internal = {
  ...
}
*/
