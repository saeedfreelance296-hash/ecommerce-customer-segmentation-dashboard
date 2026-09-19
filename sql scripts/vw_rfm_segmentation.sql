USE customer_segmetation_staging;
GO
DROP VIEW IF EXISTS gold_cust_segmentation;
GO
CREATE VIEW gold_cust_segmentation AS


-- RFM Segmentation----
-- Calculating the last order data (the most recent order) for each customer
WITH Recency AS(
	SELECT
	user_id,
	last_order_date,
	DATEDIFF(DAY, last_order_date, '2024-01-21')  AS days_since_last_order
	FROM(
		SELECT
			user_id,
			MAX(created_at) AS last_order_date -- the most recent order by user
		FROM order_items
		WHERE created_at >='2022-01-21' AND created_at <='2024-01-21'
		AND [status] IN ('Complete','Shipped','Processing','Returned')
		GROUP BY user_id

	) rec
),
Frequency AS(
-- Calculating the total number of orders per user
	SELECT
			user_id,
			COUNT(DISTINCT order_id) AS total_orders  -- the frequency of orders by user
	FROM order_items
	WHERE created_at >='2022-01-21' AND created_at <='2024-01-21'
	AND [status] IN ('Complete','Shipped','Processing','Returned')
	GROUP BY user_id
	
),
Monetary AS (
-- Calculating the total spent per user in the last two years
	SELECT 
	user_id,
	SUM(CAST(sale_price AS DECIMAL(10,2))) AS total_spent_by_customer -- monetary per user
	FROM order_items
	WHERE created_at >='2022-01-21' AND created_at <='2024-01-21'
		AND [status] IN ('Complete','Shipped','Processing')
	GROUP BY user_id
)

SELECT
user_id,
recency,
frequency,
monetary,
r_score,
f_score,
m_score,
-- customer segmentation based on rfm score and the business logic
CASE 
	WHEN f_score = 1 AND r_score >= 4 THEN 'New'
	WHEN f_score = 1 AND r_score < 4 THEN 'One-Time'
	WHEN r_score >= 4 AND f_score >= 3 THEN 'Loyal'
	WHEN r_score <= 2 AND (f_score >= 2 OR m_score >= 3) THEN 'At Risk'
	ELSE 'Others'
END AS segments
FROM(
	SELECT
	r.user_id,
	r.days_since_last_order AS recency,
	f.total_orders AS frequency,
	ISNULL(m.total_spent_by_customer, 0) AS monetary,
	-- Assigning rfm score 
	NTILE(5) OVER(ORDER BY r.days_since_last_order DESC) AS r_score,
	CASE
		WHEN f.total_orders = 1 THEN 1
		WHEN f.total_orders = 2 THEN 2
		WHEN f.total_orders = 3 THEN 3 
		ELSE 4
	END as f_score,
	NTILE(5) OVER(ORDER BY ISNULL(m.total_spent_by_customer, 0)) AS m_score

	FROM Recency r
	LEFT JOIN Frequency f ON r.user_id = f.user_id
	LEFT JOIN Monetary m ON r.user_id = m.user_id
) subquery
