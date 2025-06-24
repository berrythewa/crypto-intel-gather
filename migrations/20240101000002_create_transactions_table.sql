-- Migration: Create transactions table with TimescaleDB hypertable
-- Up: Create transactions table and convert to hypertable for time-series data

CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_id UUID NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
    tx_hash VARCHAR(66) NOT NULL,
    block_number BIGINT NOT NULL,
    from_address VARCHAR(42) NOT NULL,
    to_address VARCHAR(42) NOT NULL,
    value_wei NUMERIC(78,0) NOT NULL,
    value_usd NUMERIC(20,2),
    gas_used BIGINT,
    gas_price_wei NUMERIC(78,0),
    gas_cost_usd NUMERIC(20,2),
    status VARCHAR(20) DEFAULT 'success', -- success, failed, pending
    method_signature VARCHAR(10), -- First 4 bytes of input data
    input_data TEXT, -- Full input data for contract interactions
    
    -- Profitability tracking
    profit_usd NUMERIC(20,2), -- Profit/loss from this transaction
    profit_percentage NUMERIC(10,4), -- Profit percentage
    is_profitable_tx BOOLEAN DEFAULT FALSE, -- Whether this transaction was profitable
    
    -- Transaction classification
    tx_type VARCHAR(50), -- 'transfer', 'swap', 'liquidity', 'stake', 'unstake', 'claim'
    token_address VARCHAR(42), -- Token involved in transaction
    token_symbol VARCHAR(20), -- Token symbol for quick reference
    
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_transactions_wallet_id ON transactions(wallet_id);
CREATE INDEX idx_transactions_tx_hash ON transactions(tx_hash);
CREATE INDEX idx_transactions_timestamp ON transactions(timestamp);
CREATE INDEX idx_transactions_from_address ON transactions(from_address);
CREATE INDEX idx_transactions_to_address ON transactions(to_address);
CREATE INDEX idx_transactions_value_usd ON transactions(value_usd) WHERE value_usd IS NOT NULL;
CREATE INDEX idx_transactions_block_number ON transactions(block_number);

-- Profitability indexes
CREATE INDEX idx_transactions_profit_usd ON transactions(profit_usd DESC) WHERE profit_usd IS NOT NULL;
CREATE INDEX idx_transactions_is_profitable ON transactions(is_profitable_tx) WHERE is_profitable_tx = TRUE;
CREATE INDEX idx_transactions_profit_percentage ON transactions(profit_percentage DESC) WHERE profit_percentage > 0;

-- Transaction type and token indexes
CREATE INDEX idx_transactions_tx_type ON transactions(tx_type);
CREATE INDEX idx_transactions_token_address ON transactions(token_address);
CREATE INDEX idx_transactions_token_symbol ON transactions(token_symbol);

-- Composite indexes for common query patterns
CREATE INDEX idx_transactions_addresses ON transactions(from_address, to_address);
CREATE INDEX idx_transactions_time_value ON transactions(timestamp, value_usd DESC) WHERE value_usd > 1000;
CREATE INDEX idx_transactions_profitable_time ON transactions(timestamp, profit_usd DESC) WHERE is_profitable_tx = TRUE;

-- Convert to TimescaleDB hypertable
SELECT create_hypertable('transactions', 'timestamp', 
    chunk_time_interval => INTERVAL '1 day',
    if_not_exists => TRUE
);

-- Set compression policy (compress chunks older than 7 days)
SELECT add_compression_policy('transactions', INTERVAL '7 days');

-- Set retention policy (keep data for 2 years)
SELECT add_retention_policy('transactions', INTERVAL '2 years');

-- Create trigger to update wallet activity metrics
CREATE TRIGGER update_wallet_activity_on_transaction
    AFTER INSERT ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_wallet_activity_metrics();

-- Down: Drop transactions table and related objects
DROP TABLE IF EXISTS transactions CASCADE;