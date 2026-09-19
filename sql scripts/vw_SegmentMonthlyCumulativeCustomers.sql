WITH monthly_user_counts AS (
SELECT
	YEAR(u.created_at) AS created_year,
	MONTH(u.created_at) AS created_month,
	cs.segments,
	COUNT(DISTINCT cs.user_id) AS user_count
FROM gold_cust_segmentation cs
LEFT JOIN (SELECT id, created_at FROM dbo.users
) u ON cs.user_id = u.id 
GROUP BY  cs.segments, YEAR(u.created_at), MONTH(u.created_at)
),
 CalenderT AS (
    SELECT DISTINCT
    cs.segments,
    cal.year,
    cal.month_number
FROM gold_cust_segmentation cs
CROSS JOIN (SELECT DISTINCT year, month_number FROM CalendarTable) cal
),


Grid AS (
    SELECT
        ct.year,
        ct.month_number,
        ct.segments,
        COALESCE(muc.user_count, 0) AS user_count
    FROM CalenderT ct
    LEFT JOIN monthly_user_counts muc
        ON ct.segments = muc.segments
        AND ct.year = muc.created_year
        AND ct.month_number = muc.created_month
        
),

RunningTotals AS (
SELECT
    year,
    month_number,
    segments,
    SUM(user_count) OVER (
        PARTITION BY segments
        ORDER BY year, month_number
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS total_users
FROM Grid

)
SELECT
s.year,
s.month_number,
s.segments,
s.total_customers_that_month,
s.segment_share,
s.segment_share * monthly_email_cost AS segment_spend,
COALESCE(r.segment_monthly_sale , 0) AS segment_revenue

FROM (
    SELECT 
      r.year,
      r.month_number,
      r.segments,
     SUM(r.total_users) OVER (PARTITION BY r.year, r.month_number) AS total_customers_that_month,
     CAST(r.total_users AS DECIMAL(10,6)) /     
                        SUM(r.total_users) OVER (PARTITION BY r.year, r.month_number) AS segment_share,
     m.monthly_email_cost
    FROM RunningTotals r
    LEFT JOIN vw_MonthlyMarketingSpend m ON r.year = m.year AND r.month_number =m.month
    WHERE (r.year > 2022) OR (r.year = 2022 AND r.month_number >= 1)

) s

LEFT JOIN vw_MonthlyRevenueBySegment r 
    ON s.segments = r.segments
    AND s.year = r.year
    AND s.month_number = r.month  

;

GO
