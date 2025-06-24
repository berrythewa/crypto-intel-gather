# Containerized TimescaleDB + SQLx Migrations Guide

## 🎯 **Overview**

This guide explains how SQLx migrations work seamlessly with your containerized TimescaleDB setup for the Crypto Intel Rust backend.

## 🔄 **Architecture Flow**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   SQLx CLI      │───►│   Docker        │───►│   TimescaleDB   │
│   (cargo sqlx)  │    │   Network       │    │   Container     │
│                 │    │                 │    │                 │
│ • Migrations    │    │ • Port 5432     │    │ • PostgreSQL    │
│ • Type Gen      │    │ • Bridge        │    │ • TimescaleDB   │
│ • Schema Mgmt   │    │ • DNS           │    │ • Extensions    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 **Complete Setup Workflow**

### **Step 1: Database Container Setup**
```bash
# Run your existing script
./scripts/setup-db-sqlx.sh

# This creates:
# - TimescaleDB container (crypto-intel-timescaledb)
# - Database user with proper permissions
# - Docker network for connectivity
# - .env file with connection details
```

### **Step 2: Development Environment Setup**
```bash
# Run the new development setup script
./scripts/dev-setup.sh

# This creates:
# - .env file with DATABASE_URL pointing to container
# - SQLx CLI installation
# - Initial migration files
# - Monitoring configuration
```

### **Step 3: Migration Management**
```bash
# Create new migration
cargo sqlx migrate add create_new_table

# Edit migration file
nano migrations/YYYYMMDDHHMMSS_create_new_table.sql

# Run migration against containerized DB
cargo sqlx migrate run

# Check status
cargo sqlx migrate info
```

## 📁 **Connection Details**

### **Environment Variables (.env)**
```bash
# Created by setup-db-sqlx.sh
DATABASE_URL=postgresql://crypto_intel_user:your_password@localhost:5432/crypto_intel

# Rust Configuration
RUST_LOG=info
RUST_BACKTRACE=1
ENVIRONMENT=development
```

### **Container Connection**
- **Host**: `localhost` (from host machine) or `crypto-intel-timescaledb` (from other containers)
- **Port**: `5432` (exposed from container)
- **Database**: `crypto_intel`
- **User**: `crypto_intel_user`
- **Password**: Set during setup

## 🔧 **SQLx Commands with Containerized DB**

### **Database Operations**
```bash
# Test connection to containerized DB
cargo sqlx database create

# Run migrations against containerized DB
cargo sqlx migrate run

# Check migration status
cargo sqlx migrate info

# Revert last migration
cargo sqlx migrate revert

# Generate Rust types from containerized DB schema
cargo sqlx codegen
```

### **Development Workflow**
```bash
# 1. Start DB container (if not running)
docker compose -f docker-compose.db.yml up -d

# 2. Create new migration
cargo sqlx migrate add add_wallet_tags

# 3. Edit migration file
nano migrations/YYYYMMDDHHMMSS_add_wallet_tags.sql

# 4. Run migration
cargo sqlx migrate run

# 5. Generate updated types
cargo sqlx codegen

# 6. Build and test
cargo build
cargo test
```

## 🐳 **Docker Integration**

### **Container Management**
```bash
# Start database container
docker compose -f docker-compose.db.yml up -d

# Stop database container
docker compose -f docker-compose.db.yml down

# View database logs
docker compose -f docker-compose.db.yml logs -f crypto-intel-db

# Connect to database directly
docker compose -f docker-compose.db.yml exec crypto-intel-db psql -U crypto_intel_user -d crypto_intel
```

### **Network Connectivity**
```bash
# Check if containers can communicate
docker network ls
docker network inspect crypto-intel-network

# Test connection from host
psql postgresql://crypto_intel_user:password@localhost:5432/crypto_intel
```

## 📊 **TimescaleDB Features in Migrations**

### **Hypertables**
```sql
-- Create regular table first
CREATE TABLE transactions (
    -- ... columns
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Convert to hypertable
SELECT create_hypertable('transactions', 'timestamp', 
    chunk_time_interval => INTERVAL '1 day',
    if_not_exists => TRUE
);
```

### **Compression Policies**
```sql
-- Compress chunks older than 7 days
SELECT add_compression_policy('transactions', INTERVAL '7 days');
```

### **Retention Policies**
```sql
-- Keep data for 2 years
SELECT add_retention_policy('transactions', INTERVAL '2 years');
```

### **Continuous Aggregates**
```sql
-- Pre-compute daily summaries
CREATE MATERIALIZED VIEW daily_wallet_activity
WITH (timescaledb.continuous) AS
SELECT 
    wallet_id,
    time_bucket('1 day', timestamp) AS day,
    COUNT(*) as transaction_count,
    SUM(value_usd) as total_volume_usd
FROM transactions
GROUP BY wallet_id, day;
```

## 🧪 **Testing with Containerized DB**

### **Integration Tests**
```rust
// tests/integration_tests.rs
use sqlx::PgPool;

#[tokio::test]
async fn test_database_connection() -> Result<(), sqlx::Error> {
    let database_url = std::env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set");
    
    let pool = PgPool::connect(&database_url).await?;
    
    // Test your database operations here
    let result = sqlx::query("SELECT 1").fetch_one(&pool).await?;
    assert_eq!(result.get::<i32, _>(0), 1);
    
    Ok(())
}
```

### **Test Database Setup**
```bash
# Create test database
cargo sqlx database create --database-url postgresql://user:pass@localhost:5432/crypto_intel_test

# Run migrations on test database
DATABASE_URL=postgresql://user:pass@localhost:5432/crypto_intel_test cargo sqlx migrate run

# Run tests
DATABASE_URL=postgresql://user:pass@localhost:5432/crypto_intel_test cargo test
```

## 🔄 **Production Deployment**

### **Migration Strategy**
```bash
# 1. Backup production database
docker compose -f docker-compose.db.yml exec crypto-intel-db pg_dump -U crypto_intel_user crypto_intel > backup.sql

# 2. Run migrations
cargo sqlx migrate run

# 3. Verify migration status
cargo sqlx migrate info

# 4. Generate updated types
cargo sqlx codegen

# 5. Build and deploy application
cargo build --release
```

### **Rollback Strategy**
```bash
# If migration fails, rollback
cargo sqlx migrate revert

# Check current state
cargo sqlx migrate info

# Restore from backup if needed
docker compose -f docker-compose.db.yml exec crypto-intel-db psql -U crypto_intel_user -d crypto_intel < backup.sql
```

## 🚨 **Troubleshooting**

### **Common Issues**

**1. Connection Refused**
```bash
# Check if container is running
docker ps | grep crypto-intel-timescaledb

# Check container logs
docker compose -f docker-compose.db.yml logs crypto-intel-db

# Restart container
docker compose -f docker-compose.db.yml restart
```

**2. Permission Denied**
```bash
# Check user permissions
docker compose -f docker-compose.db.yml exec crypto-intel-db psql -U crypto_intel_user -d crypto_intel -c "\du"

# Recreate container with proper permissions
docker compose -f docker-compose.db.yml down
./scripts/setup-db-sqlx.sh
```

**3. Migration Conflicts**
```bash
# Check migration status
cargo sqlx migrate info

# Reset database (WARNING: destroys data)
cargo sqlx database reset

# Or revert specific migration
cargo sqlx migrate revert
```

### **Debug Commands**
```bash
# Test database connection
cargo sqlx database create

# Check SQLx metadata
cargo sqlx migrate info

# View database schema
docker compose -f docker-compose.db.yml exec crypto-intel-db psql -U crypto_intel_user -d crypto_intel -c "\dt"

# Check TimescaleDB extensions
docker compose -f docker-compose.db.yml exec crypto-intel-db psql -U crypto_intel_user -d crypto_intel -c "SELECT * FROM pg_extension WHERE extname = 'timescaledb';"
```

## 📋 **Best Practices**

### **Migration Development**
1. **Always test migrations** in development before production
2. **Include Down migrations** for rollback capability
3. **Use transactions** for complex migrations
4. **Document breaking changes** in migration comments
5. **Test with real data** before deploying

### **Container Management**
1. **Use volume mounts** for data persistence
2. **Set up automated backups** of the database
3. **Monitor container health** with health checks
4. **Use resource limits** to prevent container overload
5. **Keep TimescaleDB updated** for security patches

### **Performance Optimization**
1. **Use appropriate chunk intervals** for your data volume
2. **Set up compression policies** early
3. **Create indexes** on frequently queried columns
4. **Use continuous aggregates** for expensive queries
5. **Monitor query performance** with EXPLAIN ANALYZE

## 🎉 **Benefits of This Setup**

### **Development Benefits**
- **Consistent environment** across team members
- **Easy setup** with automated scripts
- **Isolated database** that doesn't interfere with other projects
- **Version-controlled schema** with SQLx migrations

### **Production Benefits**
- **Scalable architecture** with separate database container
- **Easy backup and restore** with Docker volumes
- **Monitoring integration** with Prometheus/Grafana
- **Type-safe database access** with SQLx

### **Operational Benefits**
- **Simple deployment** with Docker Compose
- **Easy rollback** with migration system
- **Performance optimization** with TimescaleDB features
- **Comprehensive monitoring** and alerting 