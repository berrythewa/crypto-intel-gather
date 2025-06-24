# SQLx Migrations for Crypto Intel Rust

## 🎯 **Why SQLx Migrations Instead of Init Scripts?**

### **Advantages of SQLx Migrations:**
- **Version Control**: Each schema change is tracked and versioned
- **Rollback Support**: Can revert to previous database states
- **Team Collaboration**: Multiple developers can share schema changes
- **Environment Consistency**: Same schema across dev, staging, prod
- **Type Safety**: SQLx generates Rust types from your schema
- **Compile-time Checks**: Database queries are validated at compile time

### **Migration vs Init Script Approach:**

| Aspect | Init Script | SQLx Migrations |
|--------|-------------|-----------------|
| **Versioning** | ❌ No version control | ✅ Tracked and versioned |
| **Rollback** | ❌ Manual rollback | ✅ Automatic rollback |
| **Team Work** | ❌ Conflicts possible | ✅ Sequential changes |
| **Type Safety** | ❌ Manual type definitions | ✅ Auto-generated types |
| **Compile Checks** | ❌ Runtime errors only | ✅ Compile-time validation |

---

## 🚀 **Setup Process**

### **1. Database Setup (One-time)**
```bash
# Run the simplified setup script
chmod +x setup-db-sqlx.sh
./setup-db-sqlx.sh
```

This creates:
- TimescaleDB container with proper permissions
- Database user and basic setup
- **No schema creation** - that's handled by migrations

### **2. SQLx CLI Setup**
```bash
# Install SQLx CLI
cargo install sqlx-cli

# Create migrations directory
mkdir -p migrations
```

### **3. Create Your First Migration**
```bash
# Create a new migration
cargo sqlx migrate add create_wallets_table

# This creates: migrations/YYYYMMDDHHMMSS_create_wallets_table.sql
```

### **4. Write Migration SQL**
Edit the generated file with your schema:

```sql
-- Up: Create wallets table
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

-- Create indexes
CREATE INDEX idx_wallets_address ON wallets(address);
CREATE INDEX idx_wallets_chain_id ON wallets(chain_id);

-- Down: Drop wallets table
DROP TABLE IF EXISTS wallets CASCADE;
```

### **5. Run Migrations**
```bash
# Apply all pending migrations
cargo sqlx migrate run

# Check migration status
cargo sqlx migrate info
```

---

## 📁 **Migration File Structure**

### **Sample Migration Files:**
```
migrations/
├── 20240101000001_create_wallets_table.sql
├── 20240101000002_create_transactions_table.sql
├── 20240101000003_create_market_data_table.sql
├── 20240101000004_create_alerts_table.sql
├── 20240101000005_create_continuous_aggregates.sql
└── 20240101000006_create_triggers.sql
```

### **Migration File Format:**
```sql
-- Up: Description of what this migration does
-- Your SQL statements here

-- Down: How to reverse this migration
-- Reverse SQL statements here
```

---

## 🔧 **SQLx Commands**

### **Migration Management:**
```bash
# Create new migration
cargo sqlx migrate add <migration_name>

# Run pending migrations
cargo sqlx migrate run

# Revert last migration
cargo sqlx migrate revert

# Check migration status
cargo sqlx migrate info

# Generate Rust types from schema
cargo sqlx codegen
```

### **Database Operations:**
```bash
# Create database
cargo sqlx database create

# Drop database
cargo sqlx database drop

# Reset database (drop + create + migrate)
cargo sqlx database reset
```

---

## 🦀 **Rust Integration**

### **1. Add SQLx to Cargo.toml:**
```toml
[dependencies]
sqlx = { version = "0.7", features = ["runtime-tokio-rustls", "postgres", "chrono", "uuid"] }
```

### **2. Database Connection:**
```rust
use sqlx::PgPool;

#[tokio::main]
async fn main() -> Result<(), sqlx::Error> {
    let database_url = "postgresql://crypto_intel_user:password@localhost:5432/crypto_intel";
    let pool = PgPool::connect(database_url).await?;
    
    // Your application code here
    Ok(())
}
```

### **3. Type-Safe Queries:**
```rust
use sqlx::Row;

// SQLx will validate this query at compile time
let wallet = sqlx::query_as!(
    Wallet,
    "SELECT * FROM wallets WHERE address = $1",
    address
)
.fetch_one(&pool)
.await?;
```

### **4. Generated Types:**
```rust
// After running: cargo sqlx codegen
#[derive(sqlx::FromRow)]
pub struct Wallet {
    pub id: uuid::Uuid,
    pub address: String,
    pub chain_id: i32,
    pub balance_wei: Option<rust_decimal::Decimal>,
    pub balance_usd: Option<rust_decimal::Decimal>,
    // ... other fields
}
```

---

## 📊 **TimescaleDB Integration**

### **Hypertables in Migrations:**
```sql
-- Create table first
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

### **Continuous Aggregates:**
```sql
-- Create continuous aggregate
CREATE MATERIALIZED VIEW daily_transaction_volume
WITH (timescaledb.continuous) AS
SELECT 
    wallet_id,
    time_bucket('1 day', timestamp) AS day,
    COUNT(*) as transaction_count,
    SUM(value_usd) as total_volume_usd
FROM transactions
GROUP BY wallet_id, day;
```

---

## 🔄 **Development Workflow**

### **1. Schema Changes:**
```bash
# 1. Create migration
cargo sqlx migrate add add_new_column_to_wallets

# 2. Edit migration file
# 3. Test migration
cargo sqlx migrate run

# 4. If needed, revert
cargo sqlx migrate revert
```

### **2. Team Collaboration:**
```bash
# 1. Pull latest changes
git pull

# 2. Run new migrations
cargo sqlx migrate run

# 3. Generate updated types
cargo sqlx codegen
```

### **3. Production Deployment:**
```bash
# 1. Build application
cargo build --release

# 2. Run migrations (if any)
cargo sqlx migrate run

# 3. Start application
./target/release/crypto-intel-rust
```

---

## ✅ **Benefits for Crypto Forensics**

### **Schema Evolution:**
- **Add new fields** to track additional wallet data
- **Create new tables** for different analysis types
- **Modify indexes** for performance optimization
- **Add TimescaleDB features** incrementally

### **Data Integrity:**
- **Foreign key constraints** ensure data consistency
- **Type safety** prevents runtime errors
- **Migration rollbacks** for safe schema changes

### **Performance:**
- **Index optimization** through migrations
- **TimescaleDB features** added incrementally
- **Query optimization** with type-safe SQL

---

## 🚨 **Important Notes**

### **Migration Best Practices:**
1. **Always include Down migration** for rollback capability
2. **Test migrations** in development before production
3. **Backup database** before running migrations in production
4. **Use transactions** for complex migrations
5. **Document breaking changes** in migration comments

### **TimescaleDB Considerations:**
1. **Hypertables** must be created after table creation
2. **Continuous aggregates** depend on existing hypertables
3. **Compression policies** can be added after data exists
4. **Retention policies** should be set up early

### **SQLx Features:**
1. **Compile-time query checking** with `query!` macros
2. **Type generation** with `cargo sqlx codegen`
3. **Migration versioning** in `_sqlx_migrations` table
4. **Connection pooling** for performance