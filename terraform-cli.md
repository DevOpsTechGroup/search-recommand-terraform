# terraform-cli

```shell
# Delete only specific terraform resources
terraform destroy \
-target=module.ecs \
-target=module.ecr \
-target=module.elb \
-target=module.security \
-target=module.storage \
| grep "module" --color=auto
```
