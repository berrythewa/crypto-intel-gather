 #!/bin/bash

set -e

echo "🔐 Setting up secure TimescaleDB for Crypto Intel Rust (SQLx Migration Approach)..."

# Default values for crypto forensics
DEFAULT_USER="crypto_intel_user"
DEFAULT_DB="crypto_intel"
DEFAULT_PASS=""

# Prompt for secrets with defaults
read -p "Enter DB username [default: $DEFAULT_USER]: " DB_USER
DB_USER=${DB_USER:-$DEFAULT_USER}

read -p "Enter DB name [default: $DEFAULT_DB]: " DB_NAME
DB_NAME=${DB_NAME:-$DEFAULT_DB}

read -s -p "Enter DB password (required): " DB_PASS
echo
if [ -z "$DB_PASS" ]; then
    echo "❌ Password is required for security"
    exit 1
fi

# Confirm
echo -e "\nSetting up Crypto Intel database with:"
echo "🧑‍💻 User: $DB_USER"
echo "📁 DB:   $DB_NAME"
echo "🔐 Password: [hidden]"

# Remove existing files if they exist
rm -f .env docker-compose.db.yml

# Create .env with crypto-specific variables
cat > .env <<EOF
# Crypto Intel Rust Database Configuration
POSTGRES_USER=$DB_USER
POSTGRES_PASSWORD=$DB_PASS
POSTGRES_DB=$DB_NAME

# TimescaleDB Configuration
TIMESCALEDB_TELEMETRY=off
POSTGRES_INITDB_ARGS="--auth-host=scram-sha-256"

# Security Settings
POSTGRES_HOST_AUTH_METHOD=scram-sha-256
EOF

chmod 600 .env
echo "✅ .env file written and secured"

# Write docker-compose.db.yml with crypto-specific configuration
cat > docker-compose.db.yml <<EOF
version: '3.8'

services:
  crypto-intel-db:
    image: timescale/timescaledb:latest-pg14
    container_name: crypto-intel-timescaledb
    ports:
      - "5432:5432"
    env_file:
      - .env
    volumes:
      - crypto-intel-data:/var/lib/postgresql/data
      - ./init-scripts:/docker-entrypoint-initdb.d
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $DB_USER -d $DB_NAME"]
      interval: 30s
      timeout: 10s
      retries: 3
    environment:
      - POSTGRES_USER=$DB_USER
      - POSTGRES_PASSWORD=$DB_PASS
      - POSTGRES_DB=$DB_NAME
      - TIMESCALEDB_TELEMETRY=off

volumes:
  crypto-intel-data:
    driver: local
EOF

echo "✅ Docker Compose file created: docker-compose.db.yml"

# Create init scripts directory
mkdir -p init-scripts

# Create minimal database initialization script (just TimescaleDB extension)
cat > init-scripts/01-init-timescaledb.sql <<EOF
-- Enable TimescaleDB extension
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Grant necessary permissions for SQLx migrations
GRANT ALL PRIVILEGES ON SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO $DB_USER;

-- Grant future permissions
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO $DB_USER;
EOF

echo "✅ TimescaleDB initialization script created: init-scripts/01-init-timescaledb.sql"

# Create connection test script
cat > test-connection.sh <<EOF
#!/bin/bash
echo "🔍 Testing database connection..."
docker compose -f docker-compose.db.yml exec crypto-intel-db psql -U $DB_USER -d $DB_NAME -c "SELECT version();"
echo "✅ Connection successful!"
EOF

chmod +x test-connection.sh

# Ask if user wants to lock .env
read -p "🔒 Make .env immutable with chattr +i? (y/N): " LOCK_IT
if [[ $LOCK_IT =~ ^[Yy]$ ]]; then
  sudo chattr +i .env
  echo "✅ .env locked (immutable)"
fi

# Start DB container
echo "🚀 Starting TimescaleDB container..."
docker compose -f docker-compose.db.yml up -d

# Wait for container to be ready
echo "⏳ Waiting for database to be ready..."
sleep 10

# Test connection
echo "🔍 Testing database connection..."
if docker compose -f docker-compose.db.yml exec crypto-intel-db pg_isready -U $DB_USER -d $DB_NAME; then
    echo "✅ TimescaleDB is ready!"
    echo "📊 Database URL: postgresql://$DB_USER:$DB_PASS@localhost:5432/$DB_NAME"
    echo "🔧 Run './test-connection.sh' to test the connection"
else
    echo "❌ Database connection failed. Check logs with:"
    echo "   docker compose -f docker-compose.db.yml logs crypto-intel-db"
fi

echo ""
echo "🎉 Crypto Intel database setup complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Update your config.toml with the database URL"
echo "   2. Create SQLx migrations: cargo sqlx migrate add <migration_name>"
echo "   3. Run migrations: cargo sqlx migrate run"
echo "   4. Start your Rust application"
echo ""
echo "🔧 Useful commands:"
echo "   - View logs: docker compose -f docker-compose.db.yml logs -f"
echo "   - Stop DB: docker compose -f docker-compose.db.yml down"
echo "   - Backup: docker compose -f docker-compose.db.yml exec crypto-intel-db pg_dump -U $DB_USER $DB_NAME > backup.sql"
echo "   - Create migration: cargo sqlx migrate add create_wallets_table"
echo "   - Run migrations: cargo sqlx migrate run"