#!/bin/bash

set -e

mkdir -p /etc/rabbitmq

rabbitmq-plugins enable rabbitmq_management

echo 'loopback_users.guest = false' >> /etc/rabbitmq/rabbitmq.conf

sudo rabbitmqctl add_user $RABBITMQ_USER $RABBITMQ_PASS || true

sudo rabbitmqctl set_permissions -p $RABBITMQ_VHOST $RABBITMQ_USER ".*" ".*" ".*" || true

exec rabbitmq-server