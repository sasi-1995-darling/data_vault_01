
---- SRC LAYER ----
WITH
SRC_R              as ( SELECT * FROM {{ ref('v_psa_stg_delivery_header__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY DELIVERY_HK ORDER BY LOAD_DTS))=1 ),
SRC_L              as ( SELECT * FROM {{ ref('v_psa_stg_delivery_line_detail__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY DELIVERY_HK ORDER BY LOAD_DTS))=1 ),
SRC_S              as ( SELECT BKCC, DELIVERY_HK, DELIVERY_BK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_shipment_item__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY DELIVERY_HK ORDER BY LOAD_DTS))=1 ),
SRC_FS              as ( SELECT BKCC, DELIVERY_HK, DELIVERY_BK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_delivery_flo_serial__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY DELIVERY_HK ORDER BY LOAD_DTS))=1 )

/*
SRC_R              as ( SELECT * FROM STAGING.V_PSA_STG_DELIVERY__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_R as (
    SELECT
        DELIVERY_HK
      , DELIVERY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_R
)

, LOGIC_L as (
    SELECT
        DELIVERY_HK
      , DELIVERY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_L
)

, LOGIC_S as (
    SELECT
        DELIVERY_HK
      , DELIVERY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S
)

, LOGIC_FS as (
    SELECT
        DELIVERY_HK
      , DELIVERY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_FS
)
---- RENAME LAYER ----

, RENAME_R as (
    SELECT
        DELIVERY_HK
      , DELIVERY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_R
)

, RENAME_L as (
    SELECT
        DELIVERY_HK
      , DELIVERY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_L
)

, RENAME_S as (
    SELECT
        DELIVERY_HK
      , DELIVERY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S
)

, RENAME_FS as (
    SELECT
        DELIVERY_HK
      , DELIVERY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_FS
)
---- FILTER LAYER ----

, FILTER_R as (
    SELECT *
    FROM RENAME_R
)

, FILTER_L as (
    SELECT *
    FROM RENAME_L
)

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)
, FILTER_FS as (
    SELECT *
    FROM RENAME_FS
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_R
    UNION ALL
    SELECT *
    FROM FILTER_L
    UNION ALL
    SELECT *
    FROM FILTER_S
    UNION ALL
    SELECT *
    FROM FILTER_FS
)

---- FINAL LAYER ----
SELECT
          DELIVERY_HK
        , DELIVERY_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.DELIVERY_HK = JOIN_RESULT.DELIVERY_HK
)
{% endif %}
QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY DELIVERY_HK ORDER BY LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS DELIVERY_HK,
GR.VALUE::text AS DELIVERY_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}