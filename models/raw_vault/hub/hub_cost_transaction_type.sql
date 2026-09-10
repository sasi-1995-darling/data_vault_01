---- SRC LAYER ----
WITH
SRC_c           as ( SELECT * FROM {{ ref('v_psa_stg_statistical_key_figure_totals__winn_sap') }} as SRC
                       QUALIFY (ROW_NUMBER() OVER(PARTITION BY COST_TRANSACTION_TYPE_HK ORDER BY LOAD_DTS ))=1 ),
SRC_d           as ( SELECT * FROM {{ ref('v_psa_stg_cost_transaction_type__winn_sap') }} as SRC
                       QUALIFY (ROW_NUMBER() OVER(PARTITION BY COST_TRANSACTION_TYPE_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_c           as ( SELECT * FROM staging.v_psa_stg_statistical_key_figure_totals__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_c as (
    SELECT
        COST_TRANSACTION_TYPE_HK
      , COST_TRANSACTION_TYPE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_c
)

, LOGIC_d as (
    SELECT
        COST_TRANSACTION_TYPE_HK
      , COST_TRANSACTION_TYPE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_d
)

---- RENAME LAYER ----

, RENAME_c as (
    SELECT
        COST_TRANSACTION_TYPE_HK
      , COST_TRANSACTION_TYPE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_c
)
, RENAME_d as (
    SELECT
        COST_TRANSACTION_TYPE_HK
      , COST_TRANSACTION_TYPE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_d
)


---- FILTER LAYER ----

, FILTER_c as (
    SELECT *
    FROM RENAME_c
)

, FILTER_d as (
    SELECT *
    FROM RENAME_d
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_c
    UNION all
    SELECT *
    FROM FILTER_d
)

---- FINAL LAYER ----
SELECT
          COST_TRANSACTION_TYPE_HK
        , COST_TRANSACTION_TYPE_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.COST_TRANSACTION_TYPE_HK = JOIN_RESULT.COST_TRANSACTION_TYPE_HK
)
{% endif %}
QUALIFY ROW_NUMBER() OVER(PARTITION BY COST_TRANSACTION_TYPE_HK, BKCC ORDER BY LOAD_DTS DESC)=1
{% if not is_incremental() %}
 union all
 SELECT
   MD5_BINARY(GR.VALUE) AS COST_TRANSACTION_TYPE_HK
 , GR.VALUE AS COST_TRANSACTION_TYPE_BK
 , DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC
 , CONVERT_TIMEZONE('UTC','1900-01-01') AS LOAD_DTS
 , 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
 FROM
 TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
 {% endif %}