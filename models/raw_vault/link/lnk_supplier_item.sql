---- SRC LAYER ----
WITH
SRC_sitmlr         as ( SELECT ITEM_HK, LNK_SUPPLIER_ITEM_HK, LOAD_DTS, REC_SRC, SUPPLIER_HK FROM {{ ref('v_psa_stg_supplier_item_loc__lrsn_psft') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_SUPPLIER_ITEM_HK ORDER BY LOAD_DTS ))=1 ),
SRC_sitme21        as ( SELECT ITEM_HK, LNK_SUPPLIER_ITEM_HK, LOAD_DTS, REC_SRC, SUPPLIER_HK FROM {{ ref('v_psa_stg_supplier_item__tt_e21') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_SUPPLIER_ITEM_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_sitmlr         as ( SELECT * FROM STAGING.v_psa_stg_supplier_item_loc__lrsn_psft )
SRC_sitme21        as ( SELECT * FROM STAGING.v_psa_stg_supplier_item_tt_e21 )
*/
---- LOGIC LAYER ----

, LOGIC_sitmlr as (
    SELECT
        LNK_SUPPLIER_ITEM_HK
      , SUPPLIER_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_sitmlr
)

, LOGIC_sitme21 as (
    SELECT
        LNK_SUPPLIER_ITEM_HK
      , SUPPLIER_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_sitme21
)
---- RENAME LAYER ----

, RENAME_sitmlr as (
    SELECT
        LNK_SUPPLIER_ITEM_HK
      , SUPPLIER_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_sitmlr
)

, RENAME_sitme21 as (
    SELECT
        LNK_SUPPLIER_ITEM_HK
      , SUPPLIER_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_sitme21
)
---- FILTER LAYER ----

, FILTER_sitmlr as (
    SELECT *
    FROM RENAME_sitmlr
)

, FILTER_sitme21 as (
    SELECT *
    FROM RENAME_sitme21
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_sitmlr
    UNION ALL
    SELECT * FROM FILTER_sitme21
)

---- FINAL LAYER ----
SELECT
          LNK_SUPPLIER_ITEM_HK
        , SUPPLIER_HK
        , ITEM_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LNK_SUPPLIER_ITEM_HK = JOIN_RESULT.LNK_SUPPLIER_ITEM_HK )
{% endif %}
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS LNK_SUPPLIER_ITEM_HK,
MD5_BINARY(GR.VALUE) AS SUPPLIER_HK,
MD5_BINARY(GR.VALUE) AS ITEM_HK,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
