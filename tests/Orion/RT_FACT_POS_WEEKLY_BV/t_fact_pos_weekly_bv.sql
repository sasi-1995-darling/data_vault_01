WITH max_date AS (
  SELECT MAX(TRANSACTION_DATE) AS last_date
  FROM {{ ref('fact_pos_weekly') }} )
SELECT 1
FROM max_date
where DATEDIFF(DAY, TO_DATE(last_date), CURRENT_TIMESTAMP) > 8