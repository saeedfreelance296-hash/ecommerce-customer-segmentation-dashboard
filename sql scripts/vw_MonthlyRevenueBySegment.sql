CREATE VIEW vw_MonthlyRevenueBySegment AS
SELECT
g.segments,
YEAR(oi.created_at) AS year,
MONTH(oi.created_at) AS month,
SUM(CAST(oi.sale_price AS DECIMAL(10,2))) AS segment_monthly_sale
FROM gold_cust_segmentation g
LEFT JOIN order_items oi ON g.user_id = oi.user_id
WHERE oi.created_at BETWEEN '2022-01-21' AND '2024-01-21'
    AND oi.status IN ('Complete', 'Shipped', 'Processing')
GROUP BY 
g.segments,
YEAR(oi.created_at),
MONTH(oi.created_at) 
 