WITH max_date AS (
    SELECT MAX(TO_TIMESTAMP_NTZ(event_action_ts)) AS last_date
    FROM {{ ref('fact_app_user_engagement_event') }}
)
SELECT *
FROM max_date
WHERE DATEDIFF('day', last_date, CURRENT_TIMESTAMP()) > 3