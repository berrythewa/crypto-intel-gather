-- Migration: Create alerts table for profitable moves and smart money tracking
-- Up: Create alerts table for storing and managing profitable wallet activity alerts

CREATE TABLE alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_type VARCHAR(50) NOT NULL, -- profitable_move, smart_money_activity, whale_movement, herd_activity, etc.
    severity VARCHAR(20) NOT NULL DEFAULT 'info', -- info, warning, success, critical
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    data JSONB, -- Additional alert data (profit amount, percentage, etc.)
    
    -- Wallet and transaction references
    wallet_id UUID REFERENCES wallets(id) ON DELETE SET NULL,
    transaction_id UUID, -- Reference to specific transaction if applicable
    token_address VARCHAR(42), -- Reference to specific token if applicable
    chain_id INTEGER,
    
    -- Profitability metrics
    profit_amount_usd NUMERIC(20,2), -- Profit amount that triggered the alert
    profit_percentage NUMERIC(10,4), -- Profit percentage
    transaction_value_usd NUMERIC(20,2), -- Value of the transaction
    
    -- Alert management
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    acknowledged_by VARCHAR(100),
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by VARCHAR(100),
    resolution_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_alerts_alert_type ON alerts(alert_type);
CREATE INDEX idx_alerts_severity ON alerts(severity);
CREATE INDEX idx_alerts_sent_at ON alerts(sent_at);
CREATE INDEX idx_alerts_wallet_id ON alerts(wallet_id);
CREATE INDEX idx_alerts_token_address ON alerts(token_address);
CREATE INDEX idx_alerts_chain_id ON alerts(chain_id);
CREATE INDEX idx_alerts_acknowledged_at ON alerts(acknowledged_at) WHERE acknowledged_at IS NULL;

-- Profitability indexes
CREATE INDEX idx_alerts_profit_amount ON alerts(profit_amount_usd DESC) WHERE profit_amount_usd IS NOT NULL;
CREATE INDEX idx_alerts_profit_percentage ON alerts(profit_percentage DESC) WHERE profit_percentage > 0;

-- Time-based indexes for recent profitable moves
CREATE INDEX idx_alerts_recent_profitable ON alerts(sent_at DESC, profit_amount_usd DESC) 
    WHERE profit_amount_usd > 1000;

-- JSONB index for flexible data queries
CREATE INDEX idx_alerts_data ON alerts USING GIN(data);

-- Create updated_at trigger
CREATE TRIGGER update_alerts_updated_at 
    BEFORE UPDATE ON alerts 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Down: Drop alerts table
DROP TABLE IF EXISTS alerts CASCADE;