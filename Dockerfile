# Multi-stage build for Crypto Intel Rust Backend
FROM rust:1.75-slim as builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy manifests
COPY Cargo.toml Cargo.lock ./

# Create a dummy main.rs to build dependencies
RUN mkdir src && echo "fn main() {}" > src/main.rs

# Build dependencies (this layer will be cached)
RUN cargo build --release

# Remove dummy main.rs and copy real source code
RUN rm src/main.rs
COPY src/ ./src/
COPY migrations/ ./migrations/

# Build the application
RUN cargo build --release

# Runtime stage
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -r -s /bin/false crypto-intel

# Set working directory
WORKDIR /app

# Copy binary from builder stage
COPY --from=builder /app/target/release/crypto-intel-rust /app/crypto-intel-rust

# Copy migrations
COPY --from=builder /app/migrations/ ./migrations/

# Create necessary directories
RUN mkdir -p /app/configs /app/logs /app/data && \
    chown -R crypto-intel:crypto-intel /app

# Switch to non-root user
USER crypto-intel

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Run the application
CMD ["/app/crypto-intel-rust"] 