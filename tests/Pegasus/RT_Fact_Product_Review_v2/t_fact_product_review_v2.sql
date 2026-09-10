WITH max_date AS (SELECT MAX(SNAPSHOTDATE) AS last_date FROM {{ ref('pb_product_review_v2') }})
SELECT * FROM max_date
WHERE DATEDIFF(day, last_date, CURRENT_TIMESTAMP) > 3