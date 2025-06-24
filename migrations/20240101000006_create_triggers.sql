-- Create a function to update wallet transaction count
CREATE OR REPLACE FUNCTION update_wallet_transaction_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE wallets 
    SET transaction_count = (
        SELECT COUNT(*) 
        FROM transactions 
        WHERE wallet_id = NEW.wallet_id
    ),
    last_updated = NOW()
    WHERE id = NEW.wallet_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update transaction count
CREATE TRIGGER trigger_update_wallet_transaction_count
    AFTER INSERT ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_wallet_transaction_count();