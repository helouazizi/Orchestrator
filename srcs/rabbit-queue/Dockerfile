FROM alpine:latest

RUN apk update && \
    apk add --no-cache \
        bash \
        curl \
        rabbitmq-server

COPY entryPoint.sh /script.sh

RUN chmod +x /script.sh

EXPOSE 5672
EXPOSE 15672
EXPOSE 15692

HEALTHCHECK \
  --interval=30s \
  --timeout=5s \
  --start-period=30s \
  --retries=3 \
CMD curl -f \
  -u "$RABBITMQ_DEFAULT_USER:$RABBITMQ_DEFAULT_PASS" \
  http://localhost:15672/api/health/checks/alarms || exit 1

ENTRYPOINT ["/script.sh"]