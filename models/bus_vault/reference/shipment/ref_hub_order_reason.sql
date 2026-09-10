---- SRC LAYER ----
WITH
SRC_OR            as ( SELECT * FROM {{ ref('v_psa_stg_order_reason__winn_sap') }} as SRC
                        QUALIFY 1 = (ROW_NUMBER() OVER(PARTITION BY ORDER_REASON_BK ORDER BY LOAD_DTS )) )
/*
SRC_OR            as ( SELECT * FROM STAGING.v_psa_stg_order_reason__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_OR as (
    SELECT
        ORDER_REASON_BK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_OR
)
---- RENAME LAYER ----

, RENAME_OR as (
    SELECT
        ORDER_REASON_BK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_OR
)
---- FILTER LAYER ----

, FILTER_OR as (
    SELECT *
    FROM RENAME_OR
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * 
    FROM FILTER_OR
)

---- FINAL LAYER ----
SELECT
          ORDER_REASON_BK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ORDER_REASON_BK = JOIN_RESULT.ORDER_REASON_BK
)
{% endif %}