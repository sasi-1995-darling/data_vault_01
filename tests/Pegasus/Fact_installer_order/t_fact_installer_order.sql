WITH max_date AS (SELECT  MAX(DATE(PB_LOAD_DTS)) AS last_date FROM {{ ref('pb_installer_order') }})
SELECT * FROM max_date
WHERE DATEDIFF(day, last_date, CURRENT_TIMESTAMP) > 3