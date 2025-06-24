-- Migration: Create triggers for wallet and transaction management
-- Up: Create triggers for automatic wallet updates and profitability tracking

-- Create a function to update wallet profitability metrics
CREATE OR REPLACE FUNCTION update_wallet_profitability()
RETURNS TRIGGER AS $$
BEGIN
    -- Update wallet profitability when transaction is inserted
    UPDATE wallets 
    SET 
        total_profit_usd = (
            SELECT COALESCE(SUM(profit_usd), 0)
            FROM transactions 
            WHERE wallet_id = NEW.wallet_id
        ),
        profit_percentage = (
            SELECT CASE 
                WHEN SUM(value_usd) > 0 THEN (SUM(profit_usd) / SUM(value_usd)) * 100
                ELSE 0
            END
            FROM transactions 
            WHERE wallet_id = NEW.wallet_id
        ),
        is_profitable = (
            SELECT CASE 
                WHEN SUM(profit_usd) > 0 THEN TRUE  -- Any positive profit = profitable
                ELSE FALSE
            END
            FROM transactions 
            WHERE wallet_id = NEW.wallet_id
        ),
        last_updated = NOW()
    WHERE id = NEW.wallet_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update profitability metrics
CREATE TRIGGER trigger_update_wallet_profitability
    AFTER INSERT OR UPDATE ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_wallet_profitability();

-- Create a function to generate profitable move alerts
CREATE OR REPLACE FUNCTION generate_profitable_move_alert()
RETURNS TRIGGER AS $$
BEGIN
    -- Generate alert for profitable moves above threshold (configurable)
    -- You can adjust this threshold in your application logic
    IF NEW.is_profitable_tx = TRUE AND NEW.profit_usd > 100 THEN  -- $100 minimum for alerts
        INSERT INTO alerts (
            alert_type,
            severity,
            title,
            message,
            data,
            wallet_id,
            transaction_id,
            token_address,
            chain_id,
            profit_amount_usd,
            profit_percentage,
            transaction_value_usd
        ) VALUES (
            'profitable_move',
            CASE 
                WHEN NEW.profit_usd > 10000 THEN 'success'  -- Big wins
                WHEN NEW.profit_usd > 1000 THEN 'warning'   -- Medium wins
                ELSE 'info'                                  -- Small wins
            END,
            'Profitable Move Detected',
            'Wallet ' || NEW.from_address || ' made a profitable move of $' || NEW.profit_usd,
            jsonb_build_object(
                'transaction_hash', NEW.tx_hash,
                'from_address', NEW.from_address,
                'to_address', NEW.to_address,
                'token_symbol', NEW.token_symbol,
                'tx_type', NEW.tx_type
            ),
            NEW.wallet_id,
            NEW.id,
            NEW.token_address,
            (SELECT chain_id FROM wallets WHERE id = NEW.wallet_id),
            NEW.profit_usd,
            NEW.profit_percentage,
            NEW.value_usd
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to generate profitable move alerts
CREATE TRIGGER trigger_generate_profitable_alert
    AFTER INSERT ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION generate_profitable_move_alert();

-- Down: Drop triggers and functions
DROP TRIGGER IF EXISTS trigger_update_wallet_profitability ON transactions;
DROP TRIGGER IF EXISTS trigger_generate_profitable_alert ON transactions;
DROP FUNCTION IF EXISTS update_wallet_profitability() CASCADE;
DROP FUNCTION IF EXISTS generate_profitable_move_alert() CASCADE;