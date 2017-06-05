#!/bin/bash
cat << EOF > /etc/ecs/ecs.config
ECS_CLUSTER=${cluster_name}
ECS_ENGINE_AUTH_TYPE=dockercfg
ECS_ENGINE_AUTH_DATA={"${docker_host}":{"auth":"${docker_auth}","username":"${docker_email}"}}
EOF
