WITH max_date AS (
  SELECT MAX(session_date__yyyymmdd) AS last_date
  FROM {{ ref('fact_ecommerce_traffic_by_session') }} ) 
SELECT 1
FROM max_date
WHERE DATEDIFF(DAY, TO_DATE(TO_VARCHAR(last_date), 'YYYYMMDD'), CURRENT_TIMESTAMP) > 2