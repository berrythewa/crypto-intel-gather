# Crypto Intel - Multi-Language Project Structure 🦀🐹🐍

## 🎯 Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Go API        │    │   Python        │
│   (Next.js)     │◄──►│   Gateway       │◄──►│   Insights      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │   Rust Backend  │
                       │   (Core Engine) │
                       └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │   TimescaleDB   │
                       │   (Data Store)  │
                       └─────────────────┘
```

## 📁 Complete Project Structure

```plaintext
crypto-intel/
├── README.md
├── docker-compose.yml                    # Main orchestration
├── .env.example
├── .gitignore
│
├── rust-backend/                         # 🦀 Core Engine
│   ├── Cargo.toml
│   ├── Cargo.lock
│   ├── src/
│   │   ├── main.rs                       # Application entry point
│   │   ├── lib.rs                        # Library entry point
│   │   ├── error.rs                      # Custom error types
│   │   ├── config/
│   │   │   ├── mod.rs
│   │   │   └── settings.rs
│   │   ├── wallet_tracker/
│   │   │   ├── mod.rs
│   │   │   ├── types.rs
│   │   │   ├── etherscan.rs
│   │   │   ├── alchemy.rs
│   │   │   └── alloy_client.rs
│   │   ├── market_watch/
│   │   │   ├── mod.rs
│   │   │   ├── types.rs
│   │   │   ├── dexscreener.rs
│   │   │   └── coingecko.rs
│   │   ├── storage/
│   │   │   ├── mod.rs
│   │   │   ├── database.rs
│   │   │   └── models.rs
│   │   ├── alerts/
│   │   │   ├── mod.rs
│   │   │   ├── engine.rs
│   │   │   └── telegram.rs
│   │   ├── evm/
│   │   │   ├── mod.rs
│   │   │   ├── types.rs
│   │   │   ├── abi.rs
│   │   │   └── contracts.rs
│   │   └── rpc_client/
│   │       ├── mod.rs
│   │       ├── alloy_provider.rs
│   │       └── websocket.rs
│   ├── migrations/                       # SQLx migrations
│   │   ├── 20240101000001_create_wallets_table.sql
│   │   ├── 20240101000002_create_transactions_table.sql
│   │   ├── 20240101000003_create_market_data_table.sql
│   │   ├── 20240101000004_create_alerts_table.sql
│   │   ├── 20240101000005_create_continuous_aggregates.sql
│   │   └── 20240101000006_create_triggers.sql
│   ├── tests/
│   │   ├── integration_tests.rs
│   │   └── common/
│   ├── configs/
│   │   ├── config.toml
│   │   └── config.dev.toml
│   ├── scripts/
│   │   ├── setup-db.sh
│   │   ├── deploy.sh
│   │   └── backup.sh
│   └── Dockerfile
│
├── go-api/                               # 🐹 API Gateway
│   ├── go.mod
│   ├── go.sum
│   ├── main.go                           # API server entry point
│   ├── cmd/
│   │   └── server/
│   │       └── main.go
│   ├── internal/
│   │   ├── api/
│   │   │   ├── handlers/
│   │   │   │   ├── wallets.go
│   │   │   │   ├── transactions.go
│   │   │   │   ├── market.go
│   │   │   │   └── alerts.go
│   │   │   ├── middleware/
│   │   │   │   ├── auth.go
│   │   │   │   ├── cors.go
│   │   │   │   ├── logging.go
│   │   │   │   └── rate_limit.go
│   │   │   ├── routes/
│   │   │   │   └── routes.go
│   │   │   └── server.go
│   │   ├── config/
│   │   │   └── config.go
│   │   ├── database/
│   │   │   ├── connection.go
│   │   │   └── queries.go
│   │   ├── models/
│   │   │   ├── wallet.go
│   │   │   ├── transaction.go
│   │   │   ├── market.go
│   │   │   └── alert.go
│   │   ├── services/
│   │   │   ├── wallet_service.go
│   │   │   ├── transaction_service.go
│   │   │   ├── market_service.go
│   │   │   └── alert_service.go
│   │   └── utils/
│   │       ├── auth.go
│   │       ├── validation.go
│   │       └── response.go
│   ├── pkg/
│   │   ├── logger/
│   │   │   └── logger.go
│   │   └── errors/
│   │       └── errors.go
│   ├── api/
│   │   └── swagger.json                  # OpenAPI spec
│   ├── configs/
│   │   ├── config.yaml
│   │   └── config.dev.yaml
│   ├── scripts/
│   │   ├── build.sh
│   │   └── deploy.sh
│   ├── Dockerfile
│   └── .env.example
│
├── python-insights/                      # 🐍 Analytics & ML
│   ├── requirements.txt
│   ├── setup.py
│   ├── pyproject.toml
│   ├── README.md
│   ├── src/
│   │   ├── crypto_intel/
│   │   │   ├── __init__.py
│   │   │   ├── config.py
│   │   │   ├── database/
│   │   │   │   ├── __init__.py
│   │   │   │   ├── connection.py
│   │   │   │   └── models.py
│   │   │   ├── analysis/
│   │   │   │   ├── __init__.py
│   │   │   │   ├── wallet_analysis.py
│   │   │   │   ├── market_analysis.py
│   │   │   │   ├── pattern_detection.py
│   │   │   │   └── risk_assessment.py
│   │   │   ├── ml/
│   │   │   │   ├── __init__.py
│   │   │   │   ├── models/
│   │   │   │   │   ├── __init__.py
│   │   │   │   │   ├── anomaly_detection.py
│   │   │   │   │   ├── clustering.py
│   │   │   │   │   └── prediction.py
│   │   │   │   ├── features/
│   │   │   │   │   ├── __init__.py
│   │   │   │   │   ├── wallet_features.py
│   │   │   │   │   └── market_features.py
│   │   │   │   └── training.py
│   │   │   ├── visualization/
│   │   │   │   ├── __init__.py
│   │   │   │   ├── charts.py
│   │   │   │   ├── network_graphs.py
│   │   │   │   └── dashboards.py
│   │   │   ├── reports/
│   │   │   │   ├── __init__.py
│   │   │   │   ├── daily_report.py
│   │   │   │   ├── wallet_report.py
│   │   │   │   └── market_report.py
│   │   │   └── utils/
│   │   │       ├── __init__.py
│   │   │       ├── data_processing.py
│   │   │       └── helpers.py
│   │   ├── scripts/
│   │   │   ├── run_analysis.py
│   │   │   ├── train_models.py
│   │   │   ├── generate_reports.py
│   │   │   └── update_dashboards.py
│   │   └── notebooks/
│   │       ├── exploratory_analysis.ipynb
│   │       ├── model_development.ipynb
│   │       ├── pattern_detection.ipynb
│   │       └── visualization_examples.ipynb
│   ├── tests/
│   │   ├── test_analysis.py
│   │   ├── test_ml.py
│   │   └── test_visualization.py
│   ├── data/
│   │   ├── raw/
│   │   ├── processed/
│   │   ├── models/
│   │   └── reports/
│   ├── configs/
│   │   ├── config.yaml
│   │   └── ml_config.yaml
│   ├── Dockerfile
│   └── .env.example
│
├── frontend/                             # 🎨 Web Dashboard (Optional)
│   ├── package.json
│   ├── next.config.js
│   ├── tailwind.config.js
│   ├── src/
│   │   ├── pages/
│   │   │   ├── index.tsx
│   │   │   ├── wallets.tsx
│   │   │   ├── transactions.tsx
│   │   │   ├── market.tsx
│   │   │   └── alerts.tsx
│   │   ├── components/
│   │   │   ├── Layout.tsx
│   │   │   ├── WalletCard.tsx
│   │   │   ├── TransactionTable.tsx
│   │   │   ├── MarketChart.tsx
│   │   │   └── AlertPanel.tsx
│   │   ├── hooks/
│   │   │   └── useApi.ts
│   │   ├── utils/
│   │   │   └── api.ts
│   │   └── styles/
│   │       └── globals.css
│   ├── public/
│   └── Dockerfile
│
├── infrastructure/                       # 🏗️ Infrastructure
│   ├── docker/
│   │   ├── rust-backend/
│   │   │   └── Dockerfile
│   │   ├── go-api/
│   │   │   └── Dockerfile
│   │   ├── python-insights/
│   │   │   └── Dockerfile
│   │   └── frontend/
│   │       └── Dockerfile
│   ├── kubernetes/
│   │   ├── namespaces/
│   │   ├── deployments/
│   │   ├── services/
│   │   ├── configmaps/
│   │   └── secrets/
│   ├── terraform/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── modules/
│   └── monitoring/
│       ├── prometheus/
│       ├── grafana/
│       └── alertmanager/
│
├── docs/                                 # 📚 Documentation
│   ├── api/
│   │   ├── rust-backend.md
│   │   ├── go-api.md
│   │   └── python-insights.md
│   ├── deployment/
│   │   ├── docker.md
│   │   ├── kubernetes.md
│   │   └── production.md
│   ├── development/
│   │   ├── setup.md
│   │   ├── contributing.md
│   │   └── testing.md
│   └── architecture/
│       ├── overview.md
│       ├── data-flow.md
│       └── security.md
│
└── scripts/                              # 🔧 Utility Scripts
    ├── setup.sh                          # Complete project setup
    ├── deploy.sh                         # Deployment script
    ├── backup.sh                         # Database backup
    ├── monitor.sh                        # Health monitoring
    └── dev.sh                            # Development environment
```

## 🔄 Data Flow Architecture

### **1. Data Ingestion (Rust Backend)**
```
Blockchain APIs → Rust Backend → TimescaleDB
     ↓
- Wallet tracking (Etherscan, Alchemy)
- Market data (DexScreener, CoinGecko)
- Transaction monitoring (Alloy RPC)
- Real-time alerts
```

### **2. API Gateway (Go)**
```
External Requests → Go API → Rust Backend → TimescaleDB
     ↓
- RESTful API endpoints
- Authentication & authorization
- Rate limiting & caching
- Request/response transformation
```

### **3. Analytics & ML (Python)**
```
TimescaleDB → Python Insights → Reports/Dashboards
     ↓
- Data analysis & pattern detection
- Machine learning models
- Visualization & reporting
- Automated insights generation
```

## 🛠️ Technology Stack

### **Rust Backend (Core Engine)**
- **Runtime**: Tokio (async)
- **Database**: SQLx + TimescaleDB
- **EVM**: Alloy
- **HTTP**: Reqwest
- **Logging**: Tracing
- **Config**: Config crate

### **Go API Gateway**
- **Framework**: Gin or Echo
- **Database**: GORM + PostgreSQL driver
- **Auth**: JWT + OAuth2
- **Validation**: Validator
- **Logging**: Logrus or Zap
- **Monitoring**: Prometheus metrics

### **Python Insights**
- **Data Processing**: Pandas, NumPy
- **ML**: Scikit-learn, TensorFlow/PyTorch
- **Visualization**: Plotly, Matplotlib, Seaborn
- **Database**: SQLAlchemy, psycopg2
- **Scheduling**: Celery, APScheduler
- **Web Framework**: FastAPI (for ML endpoints)

### **Infrastructure**
- **Containerization**: Docker
- **Orchestration**: Kubernetes
- **Database**: TimescaleDB (PostgreSQL extension)
- **Monitoring**: Prometheus + Grafana
- **CI/CD**: GitHub Actions
- **IaC**: Terraform

## 🚀 Development Workflow

### **1. Local Development Setup**
```bash
# Clone repository
git clone https://github.com/your-org/crypto-intel.git
cd crypto-intel

# Setup all services
./scripts/setup.sh

# Start development environment
./scripts/dev.sh
```

### **2. Service Communication**
```bash
# Rust Backend (Core Engine)
cd rust-backend
cargo run

# Go API Gateway
cd go-api
go run cmd/server/main.go

# Python Insights
cd python-insights
python -m crypto_intel.analysis.wallet_analysis
```

### **3. API Endpoints**
```bash
# Go API Gateway endpoints
GET  /api/v1/wallets                    # List wallets
GET  /api/v1/wallets/{address}          # Get wallet details
GET  /api/v1/transactions               # List transactions
GET  /api/v1/market/summary             # Market summary
GET  /api/v1/alerts                     # List alerts

# Python ML endpoints
POST /ml/v1/anomaly/detect              # Anomaly detection
GET  /ml/v1/patterns/wallet/{address}   # Wallet patterns
GET  /ml/v1/reports/daily               # Daily report
```

## 📊 Database Schema (Shared)

All services connect to the same TimescaleDB instance:

```sql
-- Core tables (created by Rust migrations)
wallets          -- Wallet information
transactions     -- Transaction history (hypertable)
market_data      -- Market data (hypertable)
alerts           -- Alert history

-- Analytics views (created by Python)
wallet_clusters  -- ML clustering results
risk_scores      -- Risk assessment scores
pattern_matches  -- Pattern detection results
```

## 🔐 Security Architecture

### **Authentication Flow**
```
Frontend → Go API → JWT Validation → Rust Backend → Database
     ↓
- API keys for external services
- JWT tokens for user sessions
- Database connection pooling
- Rate limiting per user/IP
```

### **Data Security**
- **Encryption**: TLS for all communications
- **Secrets**: Kubernetes secrets or HashiCorp Vault
- **Access Control**: RBAC for API endpoints
- **Audit Logging**: All database operations logged

## 📈 Scaling Strategy

### **Horizontal Scaling**
- **Rust Backend**: Multiple instances behind load balancer
- **Go API**: Stateless API servers
- **Python**: Celery workers for ML tasks
- **Database**: TimescaleDB clustering

### **Performance Optimization**
- **Caching**: Redis for API responses
- **CDN**: Static assets and reports
- **Database**: TimescaleDB compression and retention
- **Monitoring**: Real-time performance metrics

## 🎯 Benefits of This Architecture

### **Language-Specific Strengths**
- **Rust**: Performance, memory safety, async processing
- **Go**: Fast API development, excellent concurrency
- **Python**: Rich ML/analytics ecosystem, rapid prototyping

### **Operational Benefits**
- **Modularity**: Independent service development
- **Scalability**: Horizontal scaling per service
- **Maintainability**: Clear separation of concerns
- **Flexibility**: Easy to add new features or languages

### **Development Benefits**
- **Team Efficiency**: Different teams can work on different services
- **Technology Choice**: Best tool for each job
- **Testing**: Isolated testing per service
- **Deployment**: Independent deployment cycles 