FROM alpine:latest

RUN apk update && \
    apk add --no-cache bash postgresql postgresql-contrib

COPY  ./InitPgDb.sh /script.sh

RUN chmod +x /script.sh

ENTRYPOINT [ "/script.sh" ]

