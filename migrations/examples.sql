-- Get all profitable wallets
SELECT * FROM wallets WHERE is_profitable = TRUE ORDER BY total_profit_usd DESC;

-- Get recent profitable moves
SELECT * FROM alerts WHERE alert_type = 'profitable_move' ORDER BY sent_at DESC;

-- Get profitable transactions by type
SELECT tx_type, COUNT(*), AVG(profit_usd) 
FROM transactions 
WHERE is_profitable_tx = TRUE 
GROUP BY tx_type;

-- Get herd movements (wallets with similar profitable patterns)
SELECT wallet_id, COUNT(*) as profitable_tx_count, AVG(profit_percentage)
FROM transactions 
WHERE is_profitable_tx = TRUE 
GROUP BY wallet_id 
HAVING COUNT(*) > 5
ORDER BY AVG(profit_percentage) DESC;