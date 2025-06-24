-- Migration: Create continuous aggregates for performance optimization
-- Up: Create materialized views for pre-computed daily summaries with profitability focus

-- Daily wallet activity summary with profitability
CREATE MATERIALIZED VIEW daily_wallet_activity
WITH (timescaledb.continuous) AS
SELECT 
    wallet_id,
    time_bucket('1 day', timestamp) AS day,
    COUNT(*) as transaction_count,
    SUM(value_wei) as total_volume_wei,
    SUM(value_usd) as total_volume_usd,
    AVG(value_usd) as avg_transaction_value_usd,
    MIN(value_usd) as min_transaction_value_usd,
    MAX(value_usd) as max_transaction_value_usd,
    COUNT(DISTINCT tx_hash) as unique_transactions,
    -- Profitability metrics
    SUM(profit_usd) as total_profit_usd,
    AVG(profit_usd) as avg_profit_usd,
    COUNT(CASE WHEN is_profitable_tx THEN 1 END) as profitable_transactions,
    AVG(profit_percentage) as avg_profit_percentage
FROM transactions
GROUP BY wallet_id, day;

-- Daily profitable wallet summary
CREATE MATERIALIZED VIEW daily_profitable_wallets
WITH (timescaledb.continuous) AS
SELECT 
    wallet_id,
    time_bucket('1 day', timestamp) AS day,
    COUNT(*) as total_transactions,
    SUM(profit_usd) as total_profit_usd,
    AVG(profit_percentage) as avg_profit_percentage,
    COUNT(CASE WHEN is_profitable_tx THEN 1 END) as profitable_tx_count,
    SUM(CASE WHEN is_profitable_tx THEN profit_usd ELSE 0 END) as profitable_tx_profit,
    MAX(profit_usd) as max_profit_single_tx,
    MIN(profit_usd) as min_profit_single_tx
FROM transactions
WHERE profit_usd IS NOT NULL
GROUP BY wallet_id, day;

-- Daily market data summary
CREATE MATERIALIZED VIEW daily_market_summary
WITH (timescaledb.continuous) AS
SELECT 
    token_address,
    time_bucket('1 day', timestamp) AS day,
    AVG(price_usd) as avg_price_usd,
    MIN(price_usd) as min_price_usd,
    MAX(price_usd) as max_price_usd,
    AVG(volume_24h) as avg_volume_24h,
    MAX(volume_24h) as max_volume_24h,
    AVG(market_cap_usd) as avg_market_cap_usd,
    COUNT(*) as price_points
FROM market_data
GROUP BY token_address, day;

-- Daily transaction volume by chain
CREATE MATERIALIZED VIEW daily_chain_volume
WITH (timescaledb.continuous) AS
SELECT 
    w.chain_id,
    time_bucket('1 day', t.timestamp) AS day,
    COUNT(*) as transaction_count,
    SUM(t.value_wei) as total_volume_wei,
    SUM(t.value_usd) as total_volume_usd,
    COUNT(DISTINCT t.wallet_id) as active_wallets,
    AVG(t.value_usd) as avg_transaction_value_usd,
    -- Profitability by chain
    SUM(t.profit_usd) as total_profit_usd,
    COUNT(CASE WHEN t.is_profitable_tx THEN 1 END) as profitable_transactions,
    AVG(t.profit_percentage) as avg_profit_percentage
FROM transactions t
JOIN wallets w ON t.wallet_id = w.id
GROUP BY w.chain_id, day;

-- Daily profitable moves summary (for alerting)
CREATE MATERIALIZED VIEW daily_profitable_moves
WITH (timescaledb.continuous) AS
SELECT 
    time_bucket('1 day', timestamp) AS day,
    COUNT(*) as total_profitable_moves,
    COUNT(DISTINCT wallet_id) as unique_profitable_wallets,
    SUM(profit_usd) as total_profit_generated,
    AVG(profit_usd) as avg_profit_per_move,
    MAX(profit_usd) as max_profit_single_move,
    AVG(profit_percentage) as avg_profit_percentage,
    -- Token analysis
    COUNT(DISTINCT token_address) as tokens_involved,
    -- Transaction type analysis
    COUNT(DISTINCT tx_type) as transaction_types
FROM transactions
WHERE is_profitable_tx = TRUE AND profit_usd > 1000
GROUP BY day;

-- Set refresh policies for continuous aggregates
SELECT add_continuous_aggregate_policy('daily_wallet_activity',
    start_offset => INTERVAL '3 days',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour');

SELECT add_continuous_aggregate_policy('daily_profitable_wallets',
    start_offset => INTERVAL '3 days',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour');

SELECT add_continuous_aggregate_policy('daily_market_summary',
    start_offset => INTERVAL '3 days',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour');

SELECT add_continuous_aggregate_policy('daily_chain_volume',
    start_offset => INTERVAL '3 days',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour');

SELECT add_continuous_aggregate_policy('daily_profitable_moves',
    start_offset => INTERVAL '3 days',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour');

-- Down: Drop continuous aggregates
DROP MATERIALIZED VIEW IF EXISTS daily_wallet_activity CASCADE;
DROP MATERIALIZED VIEW IF EXISTS daily_profitable_wallets CASCADE;
DROP MATERIALIZED VIEW IF EXISTS daily_market_summary CASCADE;
DROP MATERIALIZED VIEW IF EXISTS daily_chain_volume CASCADE;
DROP MATERIALIZED VIEW IF EXISTS daily_profitable_moves CASCADE;