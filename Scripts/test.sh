#!/bin/bash

set -e

#upload environment variables
source ../.env


cat << end > /tmp/temp_envs/.env.rabbitmq
RABBITMQ_USER=$RABBITMQ_USER
RABBITMQ_PASS=$RABBITMQ_PASS
RABBITMQ_VHOST=$RABBITMQ_VHOST
end