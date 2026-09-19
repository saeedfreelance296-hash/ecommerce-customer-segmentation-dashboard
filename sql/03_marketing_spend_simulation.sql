
CREATE VIEW vw_MonthlyMarketingSpend AS
WITH MonthlySignups AS (
    SELECT
        YEAR(created_at) AS year,
        MONTH(created_at) AS month,
        COUNT(DISTINCT id) AS unique_users
    FROM users
    WHERE created_at BETWEEN '2022-01-21' AND '2024-01-21'
    GROUP BY YEAR(created_at), MONTH(created_at)
),

ProratedEmails AS (
    SELECT
        year,
        month,
        SUM(prorated_email) AS total_prorated_emails
    FROM (
        SELECT
            YEAR(created_at) AS year,
            MONTH(created_at) AS month,
           CAST(4.0 * (DATEDIFF(DAY, created_at, EOMONTH(created_at)) + 1)
    / DAY(EOMONTH(created_at)) AS DECIMAL(10,4)) AS prorated_email
        FROM users
        WHERE created_at BETWEEN '2022-01-21' AND '2024-01-21'
    ) subquery
    GROUP BY year, month
),

Combined AS (
    SELECT
        u.year,
        u.month,
        u.unique_users,
        SUM(u.unique_users) OVER (
            ORDER BY u.year, u.month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_customers,
        e.total_prorated_emails
    FROM MonthlySignups u
    LEFT JOIN ProratedEmails e ON u.year = e.year AND u.month = e.month
),

MonthlyEmails AS (
    SELECT
        year,
        month,
        unique_users,
        cumulative_customers,
        total_prorated_emails,
        (LAG(cumulative_customers, 1, 0) OVER (ORDER BY year, month) * 4)
            + total_prorated_emails AS month_emails
    FROM Combined
)

SELECT
    *,
    month_emails * 0.02 AS monthly_email_cost
FROM MonthlyEmails
