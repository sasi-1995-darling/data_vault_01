WITH
latest_file AS (
    SELECT _FILE
    FROM {{ source('reference', 'frontdoor_order_status_v_2') }}
    QUALIFY ROW_NUMBER() OVER (
        ORDER BY REPLACE(SUBSTR(SPLIT_PART(_FILE, '_', -1), 1, 10), '-', '') DESC
    ) = 1
),
frontdoor_email_status AS (
    SELECT
        MOEN_ORDER_NK AS ORDER_ID,
        MOEN_ORDER_STATUS,
        STATUS_GROUPING AS FRONTDOOR_STATUS_ORIG
    FROM {{ source('reference', 'frontdoor_order_status_v_2') }}
    WHERE _FILE = (SELECT _FILE FROM latest_file)
),
status_map AS (
    SELECT FRONTDOOR_STATUS, MAPPED_STATUS
    FROM {{ source('reference', 'frontdoor_status_map') }}
)
SELECT
    ROW_NUMBER() OVER (ORDER BY 1)             AS SEQ_ID,
    CURRENT_DATE                               AS SNAPSHOTDATE,
    CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP) AS PIT_LOAD_DTS,
    fes.ORDER_ID,
    CAST(NULL AS VARCHAR)                      AS BKCC,
    'BRONZE.REFERENCE.FRONTDOOR_ORDER_STATUS_V_2' AS REC_SRC,
    fes.MOEN_ORDER_STATUS,
    fes.FRONTDOOR_STATUS_ORIG,
    fsm.MAPPED_STATUS                          AS FRONTDOOR_STATUS
FROM frontdoor_email_status fes
LEFT JOIN status_map fsm
    ON fsm.FRONTDOOR_STATUS = fes.FRONTDOOR_STATUS_ORIG
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY fes.ORDER_ID
    ORDER BY
        fsm.MAPPED_STATUS ASC NULLS LAST,
        fes.FRONTDOOR_STATUS_ORIG ASC NULLS LAST,
        fes.MOEN_ORDER_STATUS ASC NULLS LAST
) = 1