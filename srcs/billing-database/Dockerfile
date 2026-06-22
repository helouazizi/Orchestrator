FROM alpine:latest

# ALPINE FIX: Added 'bash' to the installation list
RUN apk update && apk add --no-cache \
    postgresql \
    postgresql-client \
    bash

RUN mkdir -p /var/lib/postgresql/data /var/run/postgresql \
    && chown -R postgres:postgres /var/lib/postgresql/data /var/run/postgresql

ENV PGDATA="/var/lib/postgresql/data/pgdata"

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 5432

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]