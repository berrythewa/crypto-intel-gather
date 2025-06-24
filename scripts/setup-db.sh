#!/bin/bash

set -e

echo "🔐 Setting up secure TimescaleDB for Crypto Intel Rust..."

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

# Create database initialization script
cat > init-scripts/01-init-crypto-intel.sql <<EOF
-- Crypto Intel Rust Database Initialization
-- This script sets up the database schema for crypto forensics

-- Enable TimescaleDB extension
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Create wallets table
CREATE TABLE IF NOT EXISTS wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    address VARCHAR(42) NOT NULL UNIQUE,
    chain_id INTEGER NOT NULL,
    first_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    balance_wei NUMERIC,
    balance_usd NUMERIC,
    transaction_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create transactions table (TimescaleDB hypertable)
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_id UUID REFERENCES wallets(id),
    tx_hash VARCHAR(66) NOT NULL,
    block_number BIGINT,
    from_address VARCHAR(42),
    to_address VARCHAR(42),
    value_wei NUMERIC,
    value_usd NUMERIC,
    gas_used BIGINT,
    gas_price NUMERIC,
    status VARCHAR(20),
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Convert transactions to TimescaleDB hypertable
SELECT create_hypertable('transactions', 'timestamp', chunk_time_interval => INTERVAL '1 day', if_not_exists => TRUE);

-- Create market data table (TimescaleDB hypertable)
CREATE TABLE IF NOT EXISTS market_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token_address VARCHAR(42),
    token_symbol VARCHAR(20),
    price_usd NUMERIC,
    volume_24h NUMERIC,
    market_cap NUMERIC,
    price_change_24h NUMERIC,
    volume_change_24h NUMERIC,
    source VARCHAR(50),
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Convert market_data to TimescaleDB hypertable
SELECT create_hypertable('market_data', 'timestamp', chunk_time_interval => INTERVAL '1 hour', if_not_exists => TRUE);

-- Create alerts table
CREATE TABLE IF NOT EXISTS alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    message TEXT NOT NULL,
    data JSONB,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_wallets_address ON wallets(address);
CREATE INDEX IF NOT EXISTS idx_wallets_chain_id ON wallets(chain_id);
CREATE INDEX IF NOT EXISTS idx_transactions_wallet_id ON transactions(wallet_id);
CREATE INDEX IF NOT EXISTS idx_transactions_tx_hash ON transactions(tx_hash);
CREATE INDEX IF NOT EXISTS idx_transactions_timestamp ON transactions(timestamp);
CREATE INDEX IF NOT EXISTS idx_market_data_token_address ON market_data(token_address);
CREATE INDEX IF NOT EXISTS idx_market_data_timestamp ON market_data(timestamp);
CREATE INDEX IF NOT EXISTS idx_alerts_alert_type ON alerts(alert_type);
CREATE INDEX IF NOT EXISTS idx_alerts_sent_at ON alerts(sent_at);

-- Create continuous aggregates for performance
CREATE MATERIALIZED VIEW IF NOT EXISTS daily_transaction_volume
WITH (timescaledb.continuous) AS
SELECT 
    wallet_id,
    time_bucket('1 day', timestamp) AS day,
    COUNT(*) as transaction_count,
    SUM(value_usd) as total_volume_usd,
    AVG(value_usd) as avg_transaction_usd
FROM transactions
GROUP BY wallet_id, day;

CREATE MATERIALIZED VIEW IF NOT EXISTS daily_market_summary
WITH (timescaledb.continuous) AS
SELECT 
    token_address,
    token_symbol,
    time_bucket('1 day', timestamp) AS day,
    AVG(price_usd) as avg_price_usd,
    MAX(price_usd) as max_price_usd,
    MIN(price_usd) as min_price_usd,
    AVG(volume_24h) as avg_volume_24h,
    AVG(market_cap) as avg_market_cap
FROM market_data
GROUP BY token_address, token_symbol, day;

-- Set up compression policies
ALTER TABLE transactions SET (timescaledb.compress, timescaledb.compress_segmentby = 'wallet_id');
ALTER TABLE market_data SET (timescaledb.compress, timescaledb.compress_segmentby = 'token_address');

-- Enable compression after 7 days
SELECT add_compression_policy('transactions', INTERVAL '7 days');
SELECT add_compression_policy('market_data', INTERVAL '7 days');

-- Set up retention policy (keep data for 2 years)
SELECT add_retention_policy('transactions', INTERVAL '2 years');
SELECT add_retention_policy('market_data', INTERVAL '2 years');

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON daily_transaction_volume TO $DB_USER;
GRANT ALL PRIVILEGES ON daily_market_summary TO $DB_USER;

-- Create a function to update wallet transaction count
CREATE OR REPLACE FUNCTION update_wallet_transaction_count()
RETURNS TRIGGER AS \$\$
BEGIN
    UPDATE wallets 
    SET transaction_count = (
        SELECT COUNT(*) 
        FROM transactions 
        WHERE wallet_id = NEW.wallet_id
    ),
    last_updated = NOW()
    WHERE id = NEW.wallet_id;
    RETURN NEW;
END;
\$\$ LANGUAGE plpgsql;

-- Create trigger to automatically update transaction count
CREATE TRIGGER trigger_update_wallet_transaction_count
    AFTER INSERT ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_wallet_transaction_count();

-- Insert some sample data for testing
INSERT INTO wallets (address, chain_id) VALUES 
    ('0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6', 1),
    ('0x1234567890123456789012345678901234567890', 1)
ON CONFLICT (address) DO NOTHING;

EOF

echo "✅ Database initialization script created: init-scripts/01-init-crypto-intel.sql"

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
echo "   2. Run 'cargo sqlx migrate run' to apply migrations"
echo "   3. Start your Rust application"
echo ""
echo "🔧 Useful commands:"
echo "   - View logs: docker compose -f docker-compose.db.yml logs -f"
echo "   - Stop DB: docker compose -f docker-compose.db.yml down"
echo "   - Backup: docker compose -f docker-compose.db.yml exec crypto-intel-db pg_dump -U $DB_USER $DB_NAME > backup.sql"
