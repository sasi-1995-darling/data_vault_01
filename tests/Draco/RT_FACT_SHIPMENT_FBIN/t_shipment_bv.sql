WITH max_date AS (
  SELECT MAX(posted_datekey) AS last_date
  FROM {{ ref('fact_shipment_fbin') }} )
SELECT 1
FROM max_date
WHERE DATEDIFF(DAY, TO_DATE(TO_VARCHAR(last_date), 'YYYYMMDD'), CURRENT_TIMESTAMP) > 2