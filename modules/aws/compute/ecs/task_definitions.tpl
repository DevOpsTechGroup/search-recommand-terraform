[
  %{ for container in jsondecode(containers) }
  {
    "name": "${container.name}-${container.env}",
    "image": "${container.image}-${container.env}:${container.version}",
    "cpu": ${container.cpu},
    "memory": ${container.memory},
    "essential": ${container.essential},
    "portMappings": [
      %{ if container.port != 0 }
      {
        "containerPort": ${container.port},
        "hostPort": ${container.port},
        "protocol": "tcp"
      }
      %{ endif }
    ],
    "environment": [
      %{ for env_key, env_value in container.env_variables }
      {
        "name": "${env_key}",
        "value": "${env_value}"
      }%{ if env_key != keys(container.env_variables)[length(keys(container.env_variables)) - 1] },%{ endif }
      %{ endfor }
    ],
    "mountPoints": ${jsonencode(container.mount_points)},
    "healthCheck": {
      "command": ["CMD-SHELL", "${container.health_check.command}"],
      "interval": ${container.health_check.interval},
      "timeout": ${container.health_check.timeout},
      "retries": ${container.health_check.retries}
    }
  }%{ if index(jsondecode(containers), container) < length(jsondecode(containers)) - 1 },%{ endif }
  %{ endfor }
]