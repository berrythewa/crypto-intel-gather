-- Migration: Create wallets table optimized for crypto forensics
-- Up: Create wallets table with enhanced fields and indexing for blockchain analysis

CREATE TABLE wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    address VARCHAR(42) NOT NULL UNIQUE,
    chain_id INTEGER NOT NULL,
    
    -- Balance tracking
    balance_wei NUMERIC(78,0) DEFAULT 0, -- Support for very large numbers
    balance_usd NUMERIC(20,2) DEFAULT 0,
    balance_updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Transaction metrics
    transaction_count INTEGER DEFAULT 0,
    total_received_wei NUMERIC(78,0) DEFAULT 0,
    total_sent_wei NUMERIC(78,0) DEFAULT 0,
    total_received_usd NUMERIC(20,2) DEFAULT 0,
    total_sent_usd NUMERIC(20,2) DEFAULT 0,
    
    -- Profitability tracking
    total_profit_usd NUMERIC(20,2) DEFAULT 0,
    profit_percentage NUMERIC(10,4) DEFAULT 0,
    is_profitable BOOLEAN DEFAULT FALSE,
    flagged BOOLEAN DEFAULT FALSE, -- Flagged as profitable/smart money
    
    -- Activity tracking
    first_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_transaction_hash VARCHAR(66),
    
    -- Wallet classification
    is_contract BOOLEAN DEFAULT FALSE,
    contract_name VARCHAR(255), -- For verified contracts
    contract_creator VARCHAR(42), -- Address that deployed the contract
    wallet_type VARCHAR(50), -- 'eoa', 'contract', 'multisig', 'exchange', 'defi'
    
    -- Risk assessment
    risk_score INTEGER DEFAULT 0, -- 0-100 scale
    risk_factors JSONB, -- Array of risk factors
    is_suspicious BOOLEAN DEFAULT FALSE,
    
    -- Metadata and tagging
    tags JSONB DEFAULT '[]'::jsonb, -- Array of tags
    notes TEXT, -- Human-readable notes
    labels JSONB DEFAULT '{}'::jsonb, -- Key-value labels
    
    -- Performance tracking
    last_balance_check TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    check_frequency_minutes INTEGER DEFAULT 60, -- How often to check this wallet
    
    -- Audit trail
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create optimized indexes for crypto forensics queries
CREATE INDEX idx_wallets_address ON wallets(address);
CREATE INDEX idx_wallets_chain_id ON wallets(chain_id);
CREATE INDEX idx_wallets_address_chain ON wallets(address, chain_id); -- Composite for multi-chain lookups

-- Balance-based indexes for whale detection
CREATE INDEX idx_wallets_balance_usd ON wallets(balance_usd DESC) WHERE balance_usd > 1000; -- High-value wallets
CREATE INDEX idx_wallets_balance_wei ON wallets(balance_wei DESC) WHERE balance_wei > 0;

-- Activity-based indexes for monitoring
CREATE INDEX idx_wallets_last_activity ON wallets(last_activity DESC);
CREATE INDEX idx_wallets_activity_frequency ON wallets(last_activity, check_frequency_minutes);

-- Profitability and flagging indexes
CREATE INDEX idx_wallets_is_profitable ON wallets(is_profitable) WHERE is_profitable = TRUE;
CREATE INDEX idx_wallets_flagged ON wallets(flagged) WHERE flagged = TRUE;
CREATE INDEX idx_wallets_profit_usd ON wallets(total_profit_usd DESC) WHERE total_profit_usd > 0;
CREATE INDEX idx_wallets_profit_percentage ON wallets(profit_percentage DESC) WHERE profit_percentage > 0;

-- Risk and classification indexes
CREATE INDEX idx_wallets_risk_score ON wallets(risk_score DESC) WHERE risk_score > 50;
CREATE INDEX idx_wallets_is_suspicious ON wallets(is_suspicious) WHERE is_suspicious = TRUE;
CREATE INDEX idx_wallets_wallet_type ON wallets(wallet_type);
CREATE INDEX idx_wallets_is_contract ON wallets(is_contract) WHERE is_contract = TRUE;

-- JSONB indexes for efficient tag/label queries
CREATE INDEX idx_wallets_tags ON wallets USING GIN(tags);
CREATE INDEX idx_wallets_labels ON wallets USING GIN(labels);
CREATE INDEX idx_wallets_risk_factors ON wallets USING GIN(risk_factors);

-- Partial indexes for common query patterns
CREATE INDEX idx_wallets_active_high_value ON wallets(address, balance_usd) 
    WHERE balance_usd > 10000 AND last_activity > NOW() - INTERVAL '30 days';

CREATE INDEX idx_wallets_recent_contracts ON wallets(address, contract_name) 
    WHERE is_contract = TRUE AND created_at > NOW() - INTERVAL '7 days';

CREATE INDEX idx_wallets_profitable_active ON wallets(address, total_profit_usd) 
    WHERE is_profitable = TRUE AND last_activity > NOW() - INTERVAL '7 days';

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_wallets_updated_at 
    BEFORE UPDATE ON wallets 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Create function to update wallet activity metrics
CREATE OR REPLACE FUNCTION update_wallet_activity_metrics()
RETURNS TRIGGER AS $$
BEGIN
    -- Update last_activity when new transaction is inserted
    UPDATE wallets 
    SET 
        last_activity = NEW.timestamp,
        last_transaction_hash = NEW.tx_hash,
        transaction_count = transaction_count + 1,
        total_received_wei = CASE 
            WHEN NEW.to_address = address THEN total_received_wei + NEW.value_wei 
            ELSE total_received_wei 
        END,
        total_sent_wei = CASE 
            WHEN NEW.from_address = address THEN total_sent_wei + NEW.value_wei 
            ELSE total_sent_wei 
        END,
        total_received_usd = CASE 
            WHEN NEW.to_address = address THEN total_received_usd + COALESCE(NEW.value_usd, 0) 
            ELSE total_received_usd 
        END,
        total_sent_usd = CASE 
            WHEN NEW.from_address = address THEN total_sent_usd + COALESCE(NEW.value_usd, 0) 
            ELSE total_sent_usd 
        END,
        -- Calculate profitability
        total_profit_usd = CASE 
            WHEN NEW.to_address = address THEN total_profit_usd + COALESCE(NEW.value_usd, 0)
            WHEN NEW.from_address = address THEN total_profit_usd - COALESCE(NEW.value_usd, 0)
            ELSE total_profit_usd
        END,
        -- Update profit percentage
        profit_percentage = CASE 
            WHEN total_sent_usd > 0 THEN ((total_profit_usd / total_sent_usd) * 100)
            ELSE 0
        END,
        -- Flag as profitable if profit exceeds threshold
        is_profitable = CASE 
            WHEN total_profit_usd > 10000 THEN TRUE
            ELSE is_profitable
        END
    WHERE address IN (NEW.from_address, NEW.to_address);
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Down: Drop wallets table and related objects
DROP TABLE IF EXISTS wallets CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS update_wallet_activity_metrics() CASCADE; 