WITH DateSeries AS (
    -- Anchor: first day of your window
    SELECT CAST('2022-01-01' AS DATE) AS [date]

    UNION ALL

    -- Recursive part: add 1 day each time
    SELECT DATEADD(DAY, 1, [date])
    FROM DateSeries
    WHERE [date] < '2024-01-21'  -- stopping condition, matches your window end
)
SELECT
    [date],
    YEAR([date]) AS year,
    MONTH([date]) AS month_number,
    DATENAME(MONTH, [date]) AS month_name,
    DAY([date]) AS day_of_month,
    DATENAME(WEEKDAY, [date]) AS day_name,
    DATEPART(QUARTER, [date]) AS quarter,
    CONCAT('Q', DATEPART(QUARTER, [date]), ' ', YEAR([date])) AS quarter_label,
    CONCAT(DATENAME(MONTH, [date]), ' ', YEAR([date])) AS month_label
    INTO CalendarTable
FROM DateSeries
OPTION (MAXRECURSION 1000);  -- ~750 days needs a higher limit than the default 100