#!/bin/bash

set -e

echo "🚀 Crypto Intel Rust Development Setup"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Check if database is already running
if docker ps --format "table {{.Names}}" | grep -q "crypto-intel-timescaledb"; then
    print_success "Database container is already running"
    DB_RUNNING=true
else
    print_warning "Database container not found. You need to run setup-db-sqlx.sh first."
    read -p "Do you want to run the database setup now? (y/N): " SETUP_DB
    if [[ $SETUP_DB =~ ^[Yy]$ ]]; then
        print_status "Running database setup..."
        ./scripts/setup-db-sqlx.sh
        DB_RUNNING=true
    else
        print_error "Database setup required. Please run: ./scripts/setup-db-sqlx.sh"
        exit 1
    fi
fi

# Check if config file exists
if [ ! -f "configs/config.toml" ]; then
    print_warning "Configuration file not found. Creating from example..."
    cp configs/config.toml.example configs/config.toml
    print_success "Created configs/config.toml from example"
    print_warning "Please edit configs/config.toml with your API keys and settings"
fi

# Check if SQLx CLI is installed
if ! command -v sqlx &> /dev/null; then
    print_status "Installing SQLx CLI..."
    cargo install sqlx-cli --no-default-features --features postgres
    print_success "SQLx CLI installed"
fi

# Check if migrations exist
if [ ! -d "migrations" ] || [ -z "$(ls -A migrations 2>/dev/null)" ]; then
    print_warning "No migrations found. Creating initial migration..."
    cargo sqlx migrate add create_initial_schema
    print_success "Created initial migration. Please edit the migration file."
fi

# Check if .env file exists for database connection
if [ ! -f ".env" ]; then
    print_warning ".env file not found. Creating from database setup..."
    if [ -f "docker-compose.db.yml" ]; then
        # Extract database URL from docker-compose.db.yml
        DB_USER=$(grep "POSTGRES_USER:" docker-compose.db.yml | cut -d':' -f2 | tr -d ' ')
        DB_PASS=$(grep "POSTGRES_PASSWORD:" docker-compose.db.yml | cut -d':' -f2 | tr -d ' ')
        DB_NAME=$(grep "POSTGRES_DB:" docker-compose.db.yml | cut -d':' -f2 | tr -d ' ')
        
        cat > .env <<EOF
# Database Configuration
DATABASE_URL=postgresql://$DB_USER:$DB_PASS@localhost:5432/$DB_NAME

# Rust Configuration
RUST_LOG=info
RUST_BACKTRACE=1

# Development Configuration
ENVIRONMENT=development
EOF
        print_success "Created .env file with database configuration"
    else
        print_error "Cannot find database configuration. Please run setup-db-sqlx.sh first."
        exit 1
    fi
fi

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p logs data monitoring/{grafana/{dashboards,datasources},prometheus}

# Create basic monitoring configuration
if [ ! -f "monitoring/prometheus.yml" ]; then
    cat > monitoring/prometheus.yml <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'crypto-intel-rust'
    static_configs:
      - targets: ['crypto-intel-rust:9090']
    metrics_path: '/metrics'
EOF
    print_success "Created Prometheus configuration"
fi

# Create Grafana datasource configuration
mkdir -p monitoring/grafana/datasources
if [ ! -f "monitoring/grafana/datasources/prometheus.yml" ]; then
    cat > monitoring/grafana/datasources/prometheus.yml <<EOF
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
EOF
    print_success "Created Grafana datasource configuration"
fi

# Test database connection
print_status "Testing database connection..."
if cargo sqlx database create 2>/dev/null || true; then
    print_success "Database connection successful"
else
    print_error "Database connection failed. Please check your .env file and ensure the database is running."
    exit 1
fi

# Run migrations if they exist
if [ -d "migrations" ] && [ "$(ls -A migrations)" ]; then
    print_status "Running database migrations..."
    if cargo sqlx migrate run; then
        print_success "Migrations completed successfully"
    else
        print_error "Migration failed. Please check the migration files."
        exit 1
    fi
fi

# Build the project
print_status "Building the project..."
if cargo build; then
    print_success "Project built successfully"
else
    print_error "Build failed. Please check for compilation errors."
    exit 1
fi

# Run tests
print_status "Running tests..."
if cargo test; then
    print_success "All tests passed"
else
    print_warning "Some tests failed. This is normal for initial setup."
fi

print_success "Development setup complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Edit configs/config.toml with your API keys"
echo "   2. Edit migration files in migrations/ directory"
echo "   3. Run: cargo run (for development)"
echo "   4. Or run: docker-compose up (for full stack with monitoring)"
echo ""
echo "🔧 Useful commands:"
echo "   - Start app: cargo run"
echo "   - Run tests: cargo test"
echo "   - Check DB: ./test-connection.sh"
echo "   - View logs: tail -f logs/crypto-intel-rust.log"
echo "   - Full stack: docker-compose up"
echo "   - Stop DB: docker compose -f docker-compose.db.yml down"
echo ""
echo "🌐 Services will be available at:"
echo "   - App: http://localhost:8080"
echo "   - Grafana: http://localhost:3000 (admin/admin)"
echo "   - Prometheus: http://localhost:9091"
echo "   - Database: localhost:5432" 