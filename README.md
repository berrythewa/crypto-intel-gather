# Crypto Intel Rust Backend 🦀

High-performance crypto forensics backend built with Rust, Alloy, and TimescaleDB for real-time blockchain monitoring and analysis.

## 🎯 Overview

This repository contains the core engine for crypto forensics - a high-performance Rust backend that:

- **Tracks wallet activity** across multiple EVM chains using Alloy
- **Monitors market movements** via DexScreener and CoinGecko APIs
- **Stores time-series data** in TimescaleDB for efficient analytics
- **Sends real-time alerts** on interesting patterns
- **Provides foundation** for other services (Go API, Python insights)

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Blockchain    │    │   Rust Backend  │    │   TimescaleDB   │
│   APIs          │───►│   (Core Engine) │───►│   (Data Store)  │
│                 │    │                 │    │                 │
│ • Etherscan     │    │ • Wallet Tracker│    │ • Hypertables   │
│ • Alchemy       │    │ • Market Watch  │    │ • Compression   │
│ • DexScreener   │    │ • Alert Engine  │    │ • Retention     │
│ • CoinGecko     │    │ • EVM Client    │    │ • Aggregates    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- **Rust**: 1.70+ with Cargo
- **Docker**: For TimescaleDB
- **PostgreSQL**: 14+ (if not using Docker)
- **API Keys**: Etherscan, Alchemy, DexScreener

### 1. Clone Repository

```bash
git clone https://github.com/your-org/crypto-intel-rust.git
cd crypto-intel-rust
```

### 2. Setup Database

```bash
# Option A: Docker (Recommended)
chmod +x scripts/setup-db.sh
./scripts/setup-db.sh

# Option B: Manual PostgreSQL + TimescaleDB
# Follow docs/setup/database.md
```

### 3. Configure Environment

```bash
# Copy example config
cp configs/config.toml.example configs/config.toml

# Edit with your API keys
nano configs/config.toml
```

### 4. Run Migrations

```bash
# Install SQLx CLI
cargo install sqlx-cli

# Run database migrations
cargo sqlx migrate run
```

### 5. Start Application

```bash
# Development
cargo run

# Production build
cargo build --release
./target/release/crypto-intel-rust
```

## 📁 Project Structure

```plaintext
crypto-intel-rust/
├── src/
│   ├── main.rs                 # Application entry point
│   ├── lib.rs                  # Library entry point
│   ├── error.rs                # Custom error types
│   ├── config/                 # Configuration management
│   │   ├── mod.rs
│   │   └── settings.rs
│   ├── wallet_tracker/         # Wallet monitoring
│   │   ├── mod.rs
│   │   ├── types.rs
│   │   ├── etherscan.rs
│   │   ├── alchemy.rs
│   │   └── alloy_client.rs
│   ├── market_watch/           # Market data collection
│   │   ├── mod.rs
│   │   ├── types.rs
│   │   ├── dexscreener.rs
│   │   └── coingecko.rs
│   ├── storage/                # Database operations
│   │   ├── mod.rs
│   │   ├── database.rs
│   │   └── models.rs
│   ├── alerts/                 # Alert system
│   │   ├── mod.rs
│   │   ├── engine.rs
│   │   └── telegram.rs
│   ├── evm/                    # EVM utilities
│   │   ├── mod.rs
│   │   ├── types.rs
│   │   ├── abi.rs
│   │   └── contracts.rs
│   └── rpc_client/             # RPC interactions
│       ├── mod.rs
│       ├── alloy_provider.rs
│       └── websocket.rs
├── migrations/                 # SQLx migrations
│   ├── 20240101000001_create_wallets_table.sql
│   ├── 20240101000002_create_transactions_table.sql
│   ├── 20240101000003_create_market_data_table.sql
│   ├── 20240101000004_create_alerts_table.sql
│   ├── 20240101000005_create_continuous_aggregates.sql
│   └── 20240101000006_create_triggers.sql
├── tests/                      # Integration tests
├── configs/                    # Configuration files
├── scripts/                    # Utility scripts
├── docs/                       # Documentation
└── Cargo.toml                  # Dependencies
```

## 🔧 Configuration

### Environment Variables

```bash
# Database
DATABASE_URL=postgresql://user:pass@localhost/crypto_intel

# API Keys
ETHERSCAN_API_KEY=your_key_here
ALCHEMY_API_KEY=your_key_here

# Logging
RUST_LOG=info
RUST_BACKTRACE=1
```

### Configuration File (configs/config.toml)

```toml
[app]
name = "crypto-intel-rust"
version = "0.1.0"
log_level = "info"

[database]
url = "postgresql://crypto_intel_user:password@localhost/crypto_intel"
max_connections = 10
timeout_seconds = 30

[wallet_tracker]
etherscan_api_key = "your_etherscan_api_key"
alchemy_api_key = "your_alchemy_api_key"
tracking_interval_seconds = 60

[market_watch]
dexscreener_base_url = "https://api.dexscreener.com/latest"
coingecko_base_url = "https://api.coingecko.com/api/v3"
price_check_interval_seconds = 30

[alerts]
telegram_bot_token = "your_telegram_bot_token"
telegram_chat_id = "your_chat_id"
```

## 🗄️ Database Schema

### Core Tables

```sql
-- Wallets
wallets (
    id UUID PRIMARY KEY,
    address VARCHAR(42) UNIQUE,
    chain_id INTEGER,
    balance_wei NUMERIC,
    balance_usd NUMERIC,
    transaction_count INTEGER,
    first_seen TIMESTAMP,
    last_updated TIMESTAMP
)

-- Transactions (TimescaleDB Hypertable)
transactions (
    id UUID PRIMARY KEY,
    wallet_id UUID REFERENCES wallets(id),
    tx_hash VARCHAR(66),
    value_wei NUMERIC,
    value_usd NUMERIC,
    timestamp TIMESTAMP NOT NULL  -- Partition key
)

-- Market Data (TimescaleDB Hypertable)
market_data (
    id UUID PRIMARY KEY,
    token_address VARCHAR(42),
    price_usd NUMERIC,
    volume_24h NUMERIC,
    timestamp TIMESTAMP NOT NULL  -- Partition key
)

-- Alerts
alerts (
    id UUID PRIMARY KEY,
    alert_type VARCHAR(50),
    severity VARCHAR(20),
    message TEXT,
    data JSONB,
    sent_at TIMESTAMP
)
```

### TimescaleDB Features

- **Hypertables**: Automatic time-based partitioning
- **Continuous Aggregates**: Pre-computed daily summaries
- **Compression**: Automatic data compression after 7 days
- **Retention**: Automatic data cleanup after 2 years

## 🧪 Testing

### Unit Tests

```bash
# Run all tests
cargo test

# Run specific module tests
cargo test wallet_tracker

# Run with logging
RUST_LOG=debug cargo test
```

### Integration Tests

```bash
# Run integration tests
cargo test --test integration_tests

# Test with real database
DATABASE_URL=postgresql://user:pass@localhost/crypto_intel cargo test
```

### Database Tests

```bash
# Test migrations
cargo sqlx migrate run
cargo sqlx migrate revert

# Test database connection
cargo sqlx database create
cargo sqlx database drop
```

## 🚀 Deployment

### Docker

```bash
# Build image
docker build -t crypto-intel-rust .

# Run container
docker run -d \
  --name crypto-intel-rust \
  --env-file .env \
  -p 8080:8080 \
  crypto-intel-rust
```

### Systemd Service

```bash
# Install service
sudo cp systemd/crypto-intel-rust.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable crypto-intel-rust
sudo systemctl start crypto-intel-rust

# Check status
sudo systemctl status crypto-intel-rust
sudo journalctl -u crypto-intel-rust -f
```

### Kubernetes

```bash
# Apply Kubernetes manifests
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

## 📊 Monitoring

### Health Checks

```bash
# Application health
curl http://localhost:8080/health

# Database health
curl http://localhost:8080/health/db

# Metrics
curl http://localhost:8080/metrics
```

### Logging

```bash
# View logs
tail -f logs/crypto-intel-rust.log

# Structured logging with tracing
RUST_LOG=debug cargo run
```

### Metrics

- **Prometheus**: Built-in metrics endpoint
- **Grafana**: Pre-configured dashboards
- **Alerting**: Custom alert rules

## 🔄 Development Workflow

### 1. Feature Development

```bash
# Create feature branch
git checkout -b feature/wallet-tracking

# Make changes
# Run tests
cargo test

# Commit changes
git commit -m "feat: add wallet tracking"

# Push and create PR
git push origin feature/wallet-tracking
```

### 2. Database Changes

```bash
# Create migration
cargo sqlx migrate add add_new_column_to_wallets

# Edit migration file
# Run migration
cargo sqlx migrate run

# Test migration
cargo sqlx migrate revert
cargo sqlx migrate run
```

### 3. API Integration

```bash
# Test API endpoints
curl -X GET "http://localhost:8080/api/v1/wallets" \
  -H "Authorization: Bearer $API_TOKEN"

# Check API documentation
open http://localhost:8080/docs
```

## 🤝 Contributing

### Development Setup

1. **Fork** the repository
2. **Clone** your fork
3. **Setup** development environment
4. **Create** feature branch
5. **Make** changes with tests
6. **Submit** pull request

### Code Standards

- **Rust**: Follow rustfmt and clippy guidelines
- **Documentation**: Document all public APIs
- **Testing**: Maintain >80% code coverage
- **Commits**: Use conventional commit format

### Conventional Commits

```
feat: add wallet tracking functionality
fix: resolve database connection timeout
docs: update API documentation
test: add integration tests for market data
refactor: improve error handling in alerts
```

## 📚 Documentation

- **[API Reference](docs/api.md)**: Complete API documentation
- **[Architecture](docs/architecture.md)**: System design and data flow
- **[Deployment](docs/deployment.md)**: Production deployment guide
- **[Development](docs/development.md)**: Development setup and workflow
- **[Database](docs/database.md)**: Database schema and optimization

## 🔗 Related Repositories

- **[crypto-intel-api](https://github.com/your-org/crypto-intel-api)**: Go API Gateway
- **[crypto-intel-insights](https://github.com/your-org/crypto-intel-insights)**: Python Analytics
- **[crypto-intel-frontend](https://github.com/your-org/crypto-intel-frontend)**: Web Dashboard

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/your-org/crypto-intel-rust/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-org/crypto-intel-rust/discussions)
- **Documentation**: [Project Wiki](https://github.com/your-org/crypto-intel-rust/wiki)

---

**Built with ❤️ using Rust, Alloy, and TimescaleDB** 