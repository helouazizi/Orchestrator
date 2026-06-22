#!/bin/bash
set -e

# Define the target folder inside the mounted volume
DB_DATA_DIR="/var/lib/postgresql/data/pgdata"
# Define the absolute binary directory path for Ubuntu
PG_BIN_DIR="/usr/bin"

echo "Running startup environment checks as root..."

# 1. Force the 'postgres' user to own the mounted volume directory
chown -R postgres:postgres /var/lib/postgresql/data /var/run/postgresql
chmod 700 /var/lib/postgresql/data

# 2. Initialize database cluster if it doesn't exist
if [ ! -d "$DB_DATA_DIR/base" ]; then
    echo "Initializing database cluster inside subfolder..."
    
    # Use full absolute path to find initdb
    su -c "$PG_BIN_DIR/initdb -D '$DB_DATA_DIR' -U postgres" postgres
    
    # Inject network and security rules
    echo "host all all 0.0.0.0/0 md5" >> "$DB_DATA_DIR/pg_hba.conf"
    echo "host all all 0.0.0.0/0 trust" >> "$DB_DATA_DIR/pg_hba.conf"
    echo "listen_addresses='*'" >> "$DB_DATA_DIR/postgresql.conf"

    echo "Creating custom user and database..."
    # Use full absolute path to find postgres single-user mode execution
    su -c "$PG_BIN_DIR/postgres --single -D '$DB_DATA_DIR'" postgres <<EOF
CREATE USER "${POSTGRES_USER}" WITH PASSWORD '${POSTGRES_PASSWORD}';
CREATE DATABASE "${POSTGRES_DB}" OWNER "${POSTGRES_USER}";
GRANT ALL PRIVILEGES ON DATABASE "${POSTGRES_DB}" TO "${POSTGRES_USER}";
EOF

    echo "Database setup complete!"
fi

# 3. Hand control over to production PostgreSQL server AS the postgres user
echo "Dropping root privileges and starting production PostgreSQL server..."
exec su -c "$PG_BIN_DIR/postgres -D '$DB_DATA_DIR'" postgres