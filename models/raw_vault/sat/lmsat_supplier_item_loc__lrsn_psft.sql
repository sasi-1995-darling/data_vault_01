---- SRC LAYER ----
WITH
SRC_sitmlr         as ( SELECT * FROM {{ ref('v_psa_stg_supplier_item_loc__lrsn_psft') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %} )

/*
SRC_sitmlr         as ( SELECT * FROM STAGING.v_psa_stg_supplier_item_loc__lrsn_psft )
*/
---- LOGIC LAYER ----

, LOGIC_sitmlr as (
    SELECT
        LNK_SUPPLIER_ITEM_HK
      , INV_ITEM_ID
      , VENDOR_ID
      , VENDOR_SETID
      , VNDR_LOC
      , SETID
      , ACCEPT_ALL_UOM
      , ACCEPT_ALL_SHIPTO
      , QTY_TYPE
      , PRICE_DT_TYPE
      , PRICE_CAN_CHANGE
      , USE_STD_LEAD_TIME
      , LEAD_TIME
      , STOCKLESS_FLG
      , COUNTRY_IST_ORIGIN
      , IST_REGION_ORIGIN
      , LC_TEMPLATE_ID
      , ORDER_MULT_FLG
      , ROUND_RULE_ORDR
      , _FIVETRAN_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_sitmlr
)
---- RENAME LAYER ----

, RENAME_sitmlr as (
    SELECT
        LNK_SUPPLIER_ITEM_HK
      , INV_ITEM_ID
      , VENDOR_ID
      , VENDOR_SETID
      , VNDR_LOC
      , SETID
      , ACCEPT_ALL_UOM
      , ACCEPT_ALL_SHIPTO
      , QTY_TYPE
      , PRICE_DT_TYPE
      , PRICE_CAN_CHANGE
      , USE_STD_LEAD_TIME
      , LEAD_TIME
      , STOCKLESS_FLG
      , COUNTRY_IST_ORIGIN
      , IST_REGION_ORIGIN
      , LC_TEMPLATE_ID
      , ORDER_MULT_FLG
      , ROUND_RULE_ORDR
      , _FIVETRAN_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_sitmlr
)
---- FILTER LAYER ----

, FILTER_sitmlr as (
    SELECT *
    FROM RENAME_sitmlr
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_sitmlr
)

---- FINAL LAYER ----
SELECT
          LNK_SUPPLIER_ITEM_HK
        , INV_ITEM_ID
        , VENDOR_ID
        , VENDOR_SETID
        , VNDR_LOC
        , SETID
        , ACCEPT_ALL_UOM
        , ACCEPT_ALL_SHIPTO
        , QTY_TYPE
        , PRICE_DT_TYPE
        , PRICE_CAN_CHANGE
        , USE_STD_LEAD_TIME
        , LEAD_TIME
        , STOCKLESS_FLG
        , COUNTRY_IST_ORIGIN
        , IST_REGION_ORIGIN
        , LC_TEMPLATE_ID
        , ORDER_MULT_FLG
        , ROUND_RULE_ORDR
        , _FIVETRAN_ID
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , BKCC
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LNK_SUPPLIER_ITEM_HK = JOIN_RESULT.LNK_SUPPLIER_ITEM_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by LNK_SUPPLIER_ITEM_HK, VENDOR_SETID, VNDR_LOC, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS LNK_SUPPLIER_ITEM_HK,
GR.VALUE::text AS INV_ITEM_ID,
GR.VALUE::text AS VENDOR_ID,
GR.VALUE::text AS VENDOR_SETID,
GR.VALUE::text AS VNDR_LOC,
NULL AS SETID,
NULL AS ACCEPT_ALL_UOM,
NULL AS ACCEPT_ALL_SHIPTO,
NULL AS QTY_TYPE,
NULL AS PRICE_DT_TYPE,
NULL AS PRICE_CAN_CHANGE,
NULL AS USE_STD_LEAD_TIME,
NULL AS LEAD_TIME,
NULL AS STOCKLESS_FLG,
NULL AS COUNTRY_IST_ORIGIN,
NULL AS IST_REGION_ORIGIN,
NULL AS LC_TEMPLATE_ID,
NULL AS ORDER_MULT_FLG,
NULL AS ROUND_RULE_ORDR,
NULL AS _FIVETRAN_ID,
NULL AS _FIVETRAN_DELETED,
NULL AS _FIVETRAN_SYNCED,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
