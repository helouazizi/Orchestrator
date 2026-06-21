#!/bin/bash

set -e

mkdir -p /etc/rabbitmq

rabbitmq-plugins enable rabbitmq_management

echo 'loopback_users.guest = false' >> /etc/rabbitmq/rabbitmq.conf

sudo rabbitmqctl add_user $RABBITMQ_DEFAULT_USER $RABBITMQ_DEFAULT_PASS || true

sudo rabbitmqctl set_permissions -p $RABBITMQ_DEFAULT_VHOST $RABBITMQ_DEFAULT_USER ".*" ".*" ".*" || true

exec rabbitmq-server