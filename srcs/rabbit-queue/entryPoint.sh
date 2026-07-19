#!/bin/sh

set -e

mkdir -p /etc/rabbitmq

cat >/etc/rabbitmq/rabbitmq.conf <<EOF
loopback_users.guest = false
EOF

rabbitmq-plugins enable --offline rabbitmq_management rabbitmq_prometheus

rabbitmq-server &
RABBIT_PID=$!

echo "Waiting for RabbitMQ..."

until rabbitmqctl await_startup >/dev/null 2>&1
do
    sleep 2
done

echo "RabbitMQ started."

rabbitmqctl add_user \
    "$RABBITMQ_DEFAULT_USER" \
    "$RABBITMQ_DEFAULT_PASS" \
    || true

rabbitmqctl set_permissions \
    -p "$RABBITMQ_DEFAULT_VHOST" \
    "$RABBITMQ_DEFAULT_USER" \
    ".*" ".*" ".*"

rabbitmqctl set_user_tags \
    "$RABBITMQ_DEFAULT_USER" \
    administrator

wait $RABBIT_PID