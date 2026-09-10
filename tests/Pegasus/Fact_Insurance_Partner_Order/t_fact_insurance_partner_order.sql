WITH max_date AS (SELECT MAX(SNAPSHOTDATE) AS last_date FROM {{ ref('pb_insurance_partner_order') }})
SELECT * FROM max_date
WHERE DATEDIFF(day, last_date, CURRENT_TIMESTAMP) > 3