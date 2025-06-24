-- Migration: Create wallets table
-- Up: Create wallets table with proper indexing for crypto forensics

CREATE TABLE wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    address VARCHAR(42) NOT NULL UNIQUE,
    chain_id INTEGER NOT NULL,
    first_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    balance_wei NUMERIC(78,0), -- Support for very large numbers
    balance_usd NUMERIC(20,2),
    transaction_count INTEGER DEFAULT 0,
    is_contract BOOLEAN DEFAULT FALSE,
    tags JSONB, -- For storing wallet tags/notes
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_wallets_address ON wallets(address);
CREATE INDEX idx_wallets_chain_id ON wallets(chain_id);
CREATE INDEX idx_wallets_balance_usd ON wallets(balance_usd) WHERE balance_usd IS NOT NULL;
CREATE INDEX idx_wallets_updated_at ON wallets(last_updated);
CREATE INDEX idx_wallets_tags ON wallets USING GIN(tags);

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

-- Down: Drop wallets table and related objects
DROP TABLE IF EXISTS wallets CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE; 