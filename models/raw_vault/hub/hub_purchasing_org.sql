---- SRC LAYER ----
WITH
SRC_t024           as ( SELECT * FROM {{ ref('v_psa_stg_purchasing_org__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PURCHASING_ORG_HK ORDER BY LOAD_DTS ))=1 ),
SRC_marc           as ( SELECT * FROM {{ ref('v_psa_stg_plant_item__moen_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PURCHASING_ORG_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_t024           as ( SELECT * FROM staging.v_psa_stg_purchasing_org__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_t024 as (
    SELECT
        PURCHASING_ORG_HK
      , PURCHASING_ORG_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_t024
)

, LOGIC_marc as (
    SELECT
        PURCHASING_ORG_HK
      , PURCHASING_ORG_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_marc
)
---- RENAME LAYER ----

, RENAME_t024 as (
    SELECT
        PURCHASING_ORG_HK
      , PURCHASING_ORG_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_t024
)

, RENAME_marc as (
    SELECT
        PURCHASING_ORG_HK
      , PURCHASING_ORG_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_marc
)
---- FILTER LAYER ----

, FILTER_t024 as (
    SELECT *
    FROM RENAME_t024
)

, FILTER_marc as (
    SELECT *
    FROM RENAME_marc
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_t024
    UNION ALL
    SELECT *
    FROM FILTER_marc   
)

---- FINAL LAYER ----
SELECT
          PURCHASING_ORG_HK
        , PURCHASING_ORG_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT

{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PURCHASING_ORG_HK = JOIN_RESULT.PURCHASING_ORG_HK
)
{% endif %}
QUALIFY 1= ROW_NUMBER() OVER (PARTITION BY PURCHASING_ORG_BK, BKCC ORDER BY LOAD_DTS)
{% if not is_incremental() %}
union all

SELECT MD5_BINARY(GR.VALUE)  PURCHASING_ORG_HK
, GR.VALUE  AS PURCHASING_ORG_BK
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}