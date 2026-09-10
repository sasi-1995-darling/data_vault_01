---- SRC LAYER ----
WITH
SRC_TVAGT          as ( SELECT LOAD_DTS, REC_SRC, SALES_REJECTION_REASON_BK FROM {{ ref('v_psa_stg_sales_rejection_reason__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SALES_REJECTION_REASON_BK ORDER BY LOAD_DTS DESC))=1 )

/*
SRC_TVAGT          as ( SELECT * FROM STAGING.v_psa_stg_sales_rejection_reason__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_TVAGT as (
    SELECT
        SALES_REJECTION_REASON_BK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_TVAGT
)
---- RENAME LAYER ----

, RENAME_TVAGT as (
    SELECT
        SALES_REJECTION_REASON_BK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_TVAGT
)
---- FILTER LAYER ----

, FILTER_TVAGT as (
    SELECT *
    FROM RENAME_TVAGT
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_TVAGT
)

---- FINAL LAYER ----
SELECT
          SALES_REJECTION_REASON_BK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.SALES_REJECTION_REASON_BK = JOIN_RESULT.SALES_REJECTION_REASON_BK
)

{% endif %}
{% if not is_incremental() %}

union all
SELECT 
GR.VALUE::text AS SALES_REJECTION_REASON_BK,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
