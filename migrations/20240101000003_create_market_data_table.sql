-- Migration: Create market data table with TimescaleDB hypertable
-- Up: Create market data table for tracking token prices and volumes

CREATE TABLE market_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token_address VARCHAR(42) NOT NULL,
    token_symbol VARCHAR(20),
    token_name VARCHAR(100),
    price_usd NUMERIC(20,8) NOT NULL,
    volume_24h NUMERIC(20,2),
    market_cap_usd NUMERIC(20,2),
    price_change_24h_percent NUMERIC(10,4),
    volume_change_24h_percent NUMERIC(10,4),
    circulating_supply NUMERIC(30,0),
    total_supply NUMERIC(30,0),
    max_supply NUMERIC(30,0),
    ath_usd NUMERIC(20,8),
    ath_change_percent NUMERIC(10,4),
    atl_usd NUMERIC(20,8),
    atl_change_percent NUMERIC(10,4),
    source VARCHAR(50) NOT NULL, -- coingecko, dexscreener, etc.
    chain_id INTEGER,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_market_data_token_address ON market_data(token_address);
CREATE INDEX idx_market_data_timestamp ON market_data(timestamp);
CREATE INDEX idx_market_data_source ON market_data(source);
CREATE INDEX idx_market_data_chain_id ON market_data(chain_id);
CREATE INDEX idx_market_data_price_usd ON market_data(price_usd) WHERE price_usd IS NOT NULL;

-- Convert to TimescaleDB hypertable
SELECT create_hypertable('market_data', 'timestamp', 
    chunk_time_interval => INTERVAL '1 hour',
    if_not_exists => TRUE
);

-- Set compression policy (compress chunks older than 1 day)
SELECT add_compression_policy('market_data', INTERVAL '1 day');

-- Set retention policy (keep data for 1 year)
SELECT add_retention_policy('market_data', INTERVAL '1 year');

-- Down: Drop market data table
DROP TABLE IF EXISTS market_data CASCADE;