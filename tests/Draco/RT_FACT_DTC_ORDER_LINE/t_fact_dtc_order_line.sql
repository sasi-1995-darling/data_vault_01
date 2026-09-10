WITH max_date AS (
  SELECT MAX(created_date_key) AS last_date
  FROM {{ ref('fact_dtc_order_line') }} )
SELECT 1
FROM max_date
WHERE DATEDIFF(DAY, TO_DATE(TO_VARCHAR(last_date), 'YYYYMMDD'), CURRENT_TIMESTAMP) > 2