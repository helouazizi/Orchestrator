FROM alpine:latest


RUN apk update && \
    apk add bash rabbitmq-server


COPY entryPoint.sh script.sh

RUN chmod +x script.sh

EXPOSE 5672 15672

ENTRYPOINT [ "/script.sh" ]