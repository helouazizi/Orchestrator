#!/bin/sh
set -e

mkdir -p /var/lib/postgresql/data /run/postgresql
chown -R postgres:postgres /var/lib/postgresql/data /run/postgresql

echo "USER=[$BILLING_DB_USER]"
echo "PASS=[$BILLING_DB_PASS]"
echo "DB=[$BILLING_DB_NAME]"


if [ ! -s "/var/lib/postgresql/data/PG_VERSION" ]; then
    echo "First boot: Initializing database cluster..."

    su postgres -c "initdb -D /var/lib/postgresql/data"

    # Configure access BEFORE start
    echo "host all all 0.0.0.0/0 md5" >> /var/lib/postgresql/data/pg_hba.conf

    echo "listen_addresses='*'" >> /var/lib/postgresql/data/postgresql.conf

    # Start PostgreSQL temporarily
    su postgres -c "pg_ctl -D /var/lib/postgresql/data -w start"

    echo "Creating user and database..."
    su postgres -c "psql -c \"CREATE USER $BILLING_DB_USER WITH PASSWORD '$BILLING_DB_PASS';\""
    su postgres -c "psql -c \"CREATE DATABASE $BILLING_DB_NAME OWNER $BILLING_DB_USER;\""

    su postgres -c "pg_ctl -D /var/lib/postgresql/data stop"

    echo "Initialization complete."
else
    echo "Database already initialized."
fi

# FINAL RUN (foreground process)
exec su postgres -c "postgres -D /var/lib/postgresql/data"
