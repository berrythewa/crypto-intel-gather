# Phase 1 — MVP with Public APIs (Rust Backend) 🚀

## 🎯 Phase 1 Goal

Build a working crypto forensics tool that:
- Tracks wallet activity across multiple EVM chains
- Monitors market movements and token prices
- Logs events to database for analysis
- Sends alerts on interesting patterns
- Provides a foundation for Phase 2 (self-hosted node)
- **Deployed on VPS with production-ready database**

---

## 📋 Week-by-Week Implementation Plan

### Week 1: VPS Setup & Project Foundation

#### Day 1: VPS Provisioning & Initial Setup
```bash
# 1. Provision VPS (Ubuntu 22.04 LTS recommended)
# - Minimum specs: 2 CPU, 4GB RAM, 50GB SSD
# - Providers: DigitalOcean, Linode, Vultr, or AWS EC2

# 2. Initial server setup
ssh root@your-server-ip

# Update system
apt update && apt upgrade -y

# Install essential packages
apt install -y curl wget git build-essential pkg-config libssl-dev

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Install PostgreSQL
apt install -y postgresql postgresql-contrib

# Start and enable PostgreSQL
systemctl start postgresql
systemctl enable postgresql

# Configure PostgreSQL
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'your_secure_password';"
sudo -u postgres createdb crypto_intel

# Install additional tools
apt install -y nginx certbot python3-certbot-nginx
apt install -y htop iotop nethogs # monitoring tools
```

#### Day 2: Database Configuration & Security
```bash
# Configure PostgreSQL for production
sudo nano /etc/postgresql/*/main/postgresql.conf

# Add/modify these settings:
# listen_addresses = 'localhost'
# max_connections = 100
# shared_buffers = 256MB
# effective_cache_size = 1GB
# maintenance_work_mem = 64MB
# checkpoint_completion_target = 0.9
# wal_buffers = 16MB
# default_statistics_target = 100

# Configure pg_hba.conf for security
sudo nano /etc/postgresql/*/main/pg_hba.conf

# Ensure only local connections:
# local   all             postgres                                peer
# local   all             all                                     md5
# host    all             all             127.0.0.1/32            md5
# host    all             all             ::1/128                 md5

# Restart PostgreSQL
systemctl restart postgresql

# Install TimescaleDB extension
# Add TimescaleDB repository
sudo sh -c "echo 'deb https://packagecloud.io/timescale/timescaledb/ubuntu/ jammy main' > /etc/apt/sources.list.d/timescaledb.list"
wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | sudo apt-key add -
sudo apt update

# Install TimescaleDB
sudo apt install -y timescaledb-2-postgresql-14

# Enable TimescaleDB extension
sudo timescaledb-tune --quiet --yes
sudo systemctl restart postgresql

# Create application user
sudo -u postgres psql -c "CREATE USER crypto_intel_user WITH PASSWORD 'your_app_password';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE crypto_intel TO crypto_intel_user;"

# Connect to database and enable TimescaleDB
sudo -u postgres psql -d crypto_intel -c "CREATE EXTENSION IF NOT EXISTS timescaledb;"
sudo -u postgres psql -d crypto_intel -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO crypto_intel_user;"
sudo -u postgres psql -d crypto_intel -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO crypto_intel_user;"
```

#### Day 3: Project Initialization
```bash
# Create project directory
mkdir -p /opt/crypto-intel-rust
cd /opt/crypto-intel-rust

# Clone or create project
cargo new crypto-intel-rust
cd crypto-intel-rust

# Initialize git repository
git init
git add .
git commit -m "feat: initial project setup"

# Add core dependencies
cargo add tokio --features full
cargo add reqwest --features json
cargo add serde --features derive
cargo add serde_json
cargo add sqlx --features runtime-tokio-rustls,postgres,chrono
cargo add tracing tracing-subscriber
cargo add clap --features derive
cargo add config anyhow chrono uuid

# Add Alloy for EVM interactions
cargo add alloy --features full
cargo add alloy-primitives
cargo add alloy-json-abi
cargo add alloy-sol-types
```

#### Day 4: Project Structure Setup
```bash
# Create directory structure
mkdir -p src/{wallet_tracker,market_watch,storage,alerts,evm,config}
mkdir -p tests/common
mkdir -p configs
mkdir -p data
mkdir -p examples
mkdir -p docs
mkdir -p scripts/deploy
mkdir -p systemd

# Create deployment scripts
cat > scripts/deploy/setup.sh << 'EOF'
#!/bin/bash
set -e

echo "Setting up crypto-intel-rust..."

# Build the application
cargo build --release

# Create systemd service
sudo cp systemd/crypto-intel-rust.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable crypto-intel-rust

echo "Setup complete!"
EOF

chmod +x scripts/deploy/setup.sh
```

#### Day 5-7: Core Configuration & Error Handling

**Files to create:**
- `src/lib.rs` - Main library entry point
- `src/error.rs` - Custom error types
- `src/config/mod.rs` - Configuration management
- `src/config/settings.rs` - Settings structure
- `configs/config.toml` - Configuration file
- `systemd/crypto-intel-rust.service` - Systemd service file

### Week 2: Wallet Tracker Implementation

#### Day 1-3: Wallet Tracker Core
**Files to create:**
- `src/wallet_tracker/mod.rs` - Module entry point
- `src/wallet_tracker/etherscan.rs` - Etherscan API client
- `src/wallet_tracker/alchemy.rs` - Alchemy API client
- `src/wallet_tracker/alloy_client.rs` - Alloy-based client
- `src/wallet_tracker/types.rs` - Wallet tracking types

#### Day 4-5: API Integration
- Implement Etherscan API client with rate limiting
- Implement Alchemy API client for enhanced data
- Add wallet balance tracking
- Add transaction history monitoring

#### Day 6-7: Multi-Chain Support
- Add support for Ethereum mainnet
- Add support for Polygon
- Add support for BSC
- Implement chain-specific configurations

### Week 3: Market Watch Implementation

#### Day 1-3: Market Data Sources
**Files to create:**
- `src/market_watch/mod.rs` - Module entry point
- `src/market_watch/dexscreener.rs` - DexScreener API client
- `src/market_watch/coingecko.rs` - CoinGecko API client
- `src/market_watch/types.rs` - Market data types

#### Day 4-5: Price & Volume Monitoring
- Implement token price tracking
- Add volume monitoring
- Add liquidity tracking
- Implement price change alerts

#### Day 6-7: Market Analysis
- Add market cap calculations
- Implement volume spike detection
- Add price movement analysis
- Create market summary reports

### Week 4: Storage & Alert Engine

#### Day 1-3: Database Implementation
**Files to create:**
- `src/storage/mod.rs` - Module entry point
- `src/storage/database.rs` - Database connection and operations
- `src/storage/models.rs` - Database models
- `src/storage/migrations/` - SQL migrations

#### Day 4-5: Alert Engine
**Files to create:**
- `src/alerts/mod.rs` - Module entry point
- `src/alerts/engine.rs` - Alert processing engine
- `src/alerts/telegram.rs` - Telegram notification
- `src/alerts/types.rs` - Alert types and rules

#### Day 6-7: Integration & Testing
- Integrate all modules
- Add comprehensive testing
- Performance optimization
- Documentation

---

## 📁 Detailed File Structure

```plaintext
crypto-intel-rust/
├── Cargo.toml
├── Cargo.lock
├── src/
│   ├── main.rs                 # Application entry point
│   ├── lib.rs                  # Library entry point
│   ├── error.rs                # Custom error types
│   ├── wallet_tracker/
│   │   ├── mod.rs              # Module exports
│   │   ├── types.rs            # Wallet tracking types
│   │   ├── etherscan.rs        # Etherscan API client
│   │   ├── alchemy.rs          # Alchemy API client
│   │   └── alloy_client.rs     # Alloy-based client
│   ├── market_watch/
│   │   ├── mod.rs              # Module exports
│   │   ├── types.rs            # Market data types
│   │   ├── dexscreener.rs      # DexScreener API client
│   │   └── coingecko.rs        # CoinGecko API client
│   ├── storage/
│   │   ├── mod.rs              # Module exports
│   │   ├── database.rs         # Database operations
│   │   ├── models.rs           # Database models
│   │   └── migrations/         # SQL migration files
│   ├── alerts/
│   │   ├── mod.rs              # Module exports
│   │   ├── types.rs            # Alert types
│   │   ├── engine.rs           # Alert processing
│   │   └── telegram.rs         # Telegram notifications
│   ├── evm/
│   │   ├── mod.rs              # Module exports
│   │   ├── types.rs            # EVM types
│   │   ├── abi.rs              # ABI utilities
│   │   └── contracts.rs        # Contract interactions
│   └── config/
│       ├── mod.rs              # Module exports
│       └── settings.rs         # Configuration settings
├── tests/
│   ├── common/                 # Test utilities
│   ├── integration_tests.rs    # Integration tests
│   └── wallet_tracker_tests.rs # Wallet tracker tests
├── configs/
│   ├── config.toml             # Main configuration
│   ├── config.dev.toml         # Development config
│   └── config.prod.toml        # Production config
├── scripts/
│   └── deploy/
│       ├── setup.sh            # Deployment script
│       ├── backup.sh           # Database backup script
│       └── monitor.sh          # Monitoring script
├── systemd/
│   └── crypto-intel-rust.service # Systemd service file
├── data/                       # Data storage
├── examples/                   # Usage examples
├── docs/                       # Documentation
└── README.md
```

---

## 🔧 Core Dependencies & Configuration

### Cargo.toml
```toml
[package]
name = "crypto-intel-rust"
version = "0.1.0"
edition = "2021"

[dependencies]
# Async runtime
tokio = { version = "1.0", features = ["full"] }

# HTTP client
reqwest = { version = "0.11", features = ["json", "rustls-tls"] }

# Serialization
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"

# Database
sqlx = { version = "0.7", features = ["runtime-tokio-rustls", "postgres", "chrono", "uuid"] }

# Logging
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter"] }

# CLI
clap = { version = "4.0", features = ["derive"] }

# Configuration
config = "0.13"

# Error handling
anyhow = "1.0"
thiserror = "1.0"

# Time handling
chrono = { version = "0.4", features = ["serde"] }

# UUID
uuid = { version = "1.0", features = ["v4", "serde"] }

# Alloy for EVM interactions
alloy = { version = "0.1", features = ["full"] }
alloy-primitives = "0.1"
alloy-json-abi = "0.1"
alloy-sol-types = "0.1"

# Utilities
hex = "0.4"
base64 = "0.21"

[dev-dependencies]
tokio-test = "0.4"
```

### Configuration (configs/config.toml)
```toml
[app]
name = "crypto-intel-rust"
version = "0.1.0"
log_level = "info"

[database]
url = "postgresql://crypto_intel_user:your_app_password@localhost/crypto_intel"
max_connections = 10
timeout_seconds = 30

[wallet_tracker]
# Etherscan configuration
etherscan_api_key = "your_etherscan_api_key"
etherscan_base_url = "https://api.etherscan.io/api"
rate_limit_per_second = 5

# Alchemy configuration
alchemy_api_key = "your_alchemy_api_key"
alchemy_base_url = "https://eth-mainnet.g.alchemy.com/v2"

# Tracking configuration
tracking_interval_seconds = 60
max_wallets_per_request = 100

[market_watch]
# DexScreener configuration
dexscreener_base_url = "https://api.dexscreener.com/latest"
rate_limit_per_second = 10

# CoinGecko configuration
coingecko_base_url = "https://api.coingecko.com/api/v3"
rate_limit_per_second = 10

# Market monitoring
price_check_interval_seconds = 30
volume_spike_threshold = 2.0

[alerts]
# Telegram configuration
telegram_bot_token = "your_telegram_bot_token"
telegram_chat_id = "your_chat_id"

# Alert thresholds
min_transaction_value_usd = 10000
min_volume_change_percent = 50
price_change_threshold_percent = 10

[chains]
# Supported chains configuration
[[chains.ethereum]]
name = "ethereum"
chain_id = 1
rpc_url = "https://eth-mainnet.g.alchemy.com/v2/your_key"
explorer_url = "https://etherscan.io"

[[chains.polygon]]
name = "polygon"
chain_id = 137
rpc_url = "https://polygon-rpc.com"
explorer_url = "https://polygonscan.com"

[[chains.bsc]]
name = "bsc"
chain_id = 56
rpc_url = "https://bsc-dataseed.binance.org"
explorer_url = "https://bscscan.com"
```

### Systemd Service File (systemd/crypto-intel-rust.service)
```ini
[Unit]
Description=Crypto Intel Rust Service
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
User=crypto-intel
Group=crypto-intel
WorkingDirectory=/opt/crypto-intel-rust
ExecStart=/opt/crypto-intel-rust/target/release/crypto-intel-rust
Restart=always
RestartSec=10
Environment=RUST_LOG=info
Environment=RUST_BACKTRACE=1

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/crypto-intel-rust/data

[Install]
WantedBy=multi-user.target
```

---

## 🧪 Testing Strategy

### Unit Tests
- Each module should have comprehensive unit tests
- Mock external API calls
- Test error handling scenarios
- Test configuration loading

### Integration Tests
- Test database operations
- Test API integrations
- Test alert system
- Test multi-chain functionality

### Performance Tests
- Benchmark API calls
- Test database query performance
- Monitor memory usage
- Test concurrent operations

---

## 📊 Database Schema

### 🕒 TimescaleDB Benefits for Crypto Forensics

TimescaleDB is a PostgreSQL extension specifically designed for time-series data, making it perfect for blockchain analytics:

#### **Performance Benefits**
- **Hypertables**: Automatically partitions data by time for faster queries
- **Continuous Aggregates**: Pre-computed summaries for common time-based queries
- **Compression**: Automatic data compression to reduce storage costs
- **Retention Policies**: Automatic data lifecycle management

#### **Crypto Forensics Use Cases**
- **Transaction Analysis**: Fast queries across time ranges for wallet activity
- **Market Data**: Efficient storage and querying of price/volume time series
- **Pattern Detection**: Time-based aggregations for identifying trading patterns
- **Historical Analysis**: Long-term data retention with automatic partitioning

#### **Configuration Optimization**
```sql
-- Set up compression for old data
ALTER TABLE transactions SET (timescaledb.compress, timescaledb.compress_segmentby = 'wallet_id');
ALTER TABLE market_data SET (timescaledb.compress, timescaledb.compress_segmentby = 'token_address');

-- Enable compression after 7 days
SELECT add_compression_policy('transactions', INTERVAL '7 days');
SELECT add_compression_policy('market_data', INTERVAL '7 days');

-- Set up retention policy (keep data for 2 years)
SELECT add_retention_policy('transactions', INTERVAL '2 years');
SELECT add_retention_policy('market_data', INTERVAL '2 years');
```

### Tables Structure

```sql
-- Enable TimescaleDB extension
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Wallets table
CREATE TABLE wallets (
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

-- Transactions table (TimescaleDB hypertable for time-series optimization)
CREATE TABLE transactions (
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
SELECT create_hypertable('transactions', 'timestamp', chunk_time_interval => INTERVAL '1 day');

-- Market data table (TimescaleDB hypertable for time-series optimization)
CREATE TABLE market_data (
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
SELECT create_hypertable('market_data', 'timestamp', chunk_time_interval => INTERVAL '1 hour');

-- Alerts table
CREATE TABLE alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    message TEXT NOT NULL,
    data JSONB,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_wallets_address ON wallets(address);
CREATE INDEX idx_wallets_chain_id ON wallets(chain_id);
CREATE INDEX idx_transactions_wallet_id ON transactions(wallet_id);
CREATE INDEX idx_transactions_tx_hash ON transactions(tx_hash);
CREATE INDEX idx_transactions_timestamp ON transactions(timestamp);
CREATE INDEX idx_market_data_token_address ON market_data(token_address);
CREATE INDEX idx_market_data_timestamp ON market_data(timestamp);
CREATE INDEX idx_alerts_alert_type ON alerts(alert_type);
CREATE INDEX idx_alerts_sent_at ON alerts(sent_at);

-- TimescaleDB continuous aggregates for performance
-- Daily transaction volume by wallet
CREATE MATERIALIZED VIEW daily_transaction_volume
WITH (timescaledb.continuous) AS
SELECT 
    wallet_id,
    time_bucket('1 day', timestamp) AS day,
    COUNT(*) as transaction_count,
    SUM(value_usd) as total_volume_usd,
    AVG(value_usd) as avg_transaction_usd
FROM transactions
GROUP BY wallet_id, day;

-- Daily market data summary
CREATE MATERIALIZED VIEW daily_market_summary
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

-- Grant permissions on continuous aggregates
GRANT ALL PRIVILEGES ON daily_transaction_volume TO crypto_intel_user;
GRANT ALL PRIVILEGES ON daily_market_summary TO crypto_intel_user;
```

---

## 🚀 Getting Started Commands

```bash
# 1. VPS Setup (Day 1-2)
# Follow the VPS provisioning steps above

# 2. Create project
cd /opt
cargo new crypto-intel-rust
cd crypto-intel-rust

# 3. Add dependencies
cargo add tokio --features full
cargo add reqwest --features json
cargo add serde --features derive
cargo add sqlx --features runtime-tokio-rustls,postgres,chrono
cargo add tracing tracing-subscriber
cargo add clap --features derive
cargo add config anyhow chrono uuid
cargo add alloy --features full
cargo add alloy-primitives alloy-json-abi alloy-sol-types

# 4. Set up database (already done in Day 2)
# Database is configured and ready

# 5. Run migrations
cargo sqlx migrate run

# 6. Set up configuration
cp configs/config.toml.example configs/config.toml
# Edit config.toml with your API keys

# 7. Create system user
sudo useradd -r -s /bin/false crypto-intel
sudo chown -R crypto-intel:crypto-intel /opt/crypto-intel-rust

# 8. Build and deploy
cargo build --release
sudo ./scripts/deploy/setup.sh

# 9. Start the service
sudo systemctl start crypto-intel-rust
sudo systemctl status crypto-intel-rust

# 10. Check logs
sudo journalctl -u crypto-intel-rust -f
```

---

## 🔒 Security Considerations

### VPS Security
- **Firewall setup**: Configure UFW or iptables
- **SSH hardening**: Disable root login, use key-based auth
- **Regular updates**: Set up automatic security updates
- **Monitoring**: Install fail2ban and monitoring tools

### Database Security
- **Strong passwords**: Use complex passwords for all database users
- **Network isolation**: Only allow local connections
- **Regular backups**: Set up automated database backups
- **SSL connections**: Enable SSL for database connections

### Application Security
- **Environment variables**: Store sensitive data in environment variables
- **Input validation**: Validate all external inputs
- **Rate limiting**: Implement proper rate limiting for APIs
- **Logging**: Log security events and errors

---

## 📈 Monitoring & Maintenance

### System Monitoring
```bash
# Create monitoring script
cat > scripts/deploy/monitor.sh << 'EOF'
#!/bin/bash

# Check service status
if ! systemctl is-active --quiet crypto-intel-rust; then
    echo "Service is down! Restarting..."
    systemctl restart crypto-intel-rust
fi

# Check database connections
DB_CONNECTIONS=$(psql -h localhost -U crypto_intel_user -d crypto_intel -c "SELECT count(*) FROM pg_stat_activity;" -t)
echo "Active database connections: $DB_CONNECTIONS"

# Check disk space
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "Warning: Disk usage is ${DISK_USAGE}%"
fi

# Check memory usage
MEM_USAGE=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100.0)}')
echo "Memory usage: ${MEM_USAGE}%"
EOF

chmod +x scripts/deploy/monitor.sh

# Add to crontab for regular monitoring
echo "*/5 * * * * /opt/crypto-intel-rust/scripts/deploy/monitor.sh" | crontab -
```

### Database Backup
```bash
# Create backup script
cat > scripts/deploy/backup.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="/opt/crypto-intel-rust/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/crypto_intel_$DATE.sql"

mkdir -p $BACKUP_DIR

# Create backup with TimescaleDB considerations
pg_dump -h localhost -U crypto_intel_user crypto_intel \
  --verbose \
  --clean \
  --if-exists \
  --create \
  --no-owner \
  --no-privileges \
  --exclude-table-data='_timescaledb_internal.*' \
  > $BACKUP_FILE

# Compress backup
gzip $BACKUP_FILE

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete

echo "Backup created: ${BACKUP_FILE}.gz"

# Optional: Create TimescaleDB-specific backup for continuous aggregates
CONTINUOUS_BACKUP_FILE="$BACKUP_DIR/continuous_aggregates_$DATE.sql"
pg_dump -h localhost -U crypto_intel_user crypto_intel \
  --table='daily_transaction_volume' \
  --table='daily_market_summary' \
  --data-only \
  > $CONTINUOUS_BACKUP_FILE

gzip $CONTINUOUS_BACKUP_FILE
echo "Continuous aggregates backup created: ${CONTINUOUS_BACKUP_FILE}.gz"
EOF

chmod +x scripts/deploy/backup.sh

# Add to crontab for daily backups
echo "0 2 * * * /opt/crypto-intel-rust/scripts/deploy/backup.sh" | crontab -
```

---

## ✅ Success Criteria

By the end of Phase 1, you should have:

1. ✅ **VPS provisioned and secured** with proper firewall and monitoring
2. ✅ **PostgreSQL database** configured and optimized for production
3. ✅ **Working wallet tracker** that monitors multiple EVM chains
4. ✅ **Market data collector** that tracks prices and volumes
5. ✅ **Database storage** with proper schema and migrations
6. ✅ **Alert system** that sends notifications on interesting events
7. ✅ **Systemd service** for automatic startup and management
8. ✅ **Comprehensive testing** with unit and integration tests
9. ✅ **Configuration management** for different environments
10. ✅ **Logging system** for debugging and monitoring
11. ✅ **CLI interface** for easy operation
12. ✅ **Backup and monitoring** scripts for production reliability

---

## 🔄 Next Steps After Phase 1

1. **Performance optimization** based on real-world usage
2. **Additional data sources** (more APIs, DEX data)
3. **Advanced alerting rules** based on patterns
4. **Data analysis tools** for historical analysis
5. **Preparation for Phase 2** (self-hosted node integration)
6. **Web dashboard** for monitoring and control

---

## 📝 Development Notes

- **Error Handling**: Use `anyhow` for application errors and `thiserror` for library errors
- **Logging**: Use structured logging with `tracing` for better observability
- **Configuration**: Use environment variables for sensitive data
- **Testing**: Aim for >80% code coverage
- **Documentation**: Document all public APIs and configuration options
- **Security**: Never commit API keys to version control
- **VPS Management**: Regular security updates and monitoring
- **Database**: Regular backups and performance monitoring 