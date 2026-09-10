---- SRC LAYER ----
WITH
SRC_sitme21        as ( SELECT * FROM {{ ref('v_psa_stg_supplier_item__tt_e21') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_sitme21        as ( SELECT * FROM STAGING.v_psa_stg_supplier_item_tt_e21 )
*/
---- LOGIC LAYER ----

, LOGIC_sitme21 as (
    SELECT
        LNK_SUPPLIER_ITEM_HK
      , VEND_CODE
      , PART_CODE
      , WARRANTEE_TYPE
      , ORIGIN_COUNTRY
      , LEAD_DAYS
      , YTD_ACTIVITY
      , MIN_ORD_QTY
      , PART_IDENT
      , PACK_QTY
      , PREF_FLG
      , VPART_DESC
      , CYCLE_TIME
      , LAST_TAG
      , LAST_ACTIVITY
      , WARRANTEE_PER
      , VEND_PART
      , DROP_SHIP
      , AGREEMENT_NO
      , YTD_PUR_UNIT
      , WARRANTEE_FLAG
      , VEND_NAME
      , VEND_SITE
      , BUYER_CODE
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
    FROM SRC_sitme21
)
---- RENAME LAYER ----

, RENAME_sitme21 as (
    SELECT
        LNK_SUPPLIER_ITEM_HK
      , VEND_CODE
      , PART_CODE
      , WARRANTEE_TYPE
      , ORIGIN_COUNTRY
      , LEAD_DAYS
      , YTD_ACTIVITY
      , MIN_ORD_QTY
      , PART_IDENT
      , PACK_QTY
      , PREF_FLG
      , VPART_DESC
      , CYCLE_TIME
      , LAST_TAG
      , LAST_ACTIVITY
      , WARRANTEE_PER
      , VEND_PART
      , DROP_SHIP
      , AGREEMENT_NO
      , YTD_PUR_UNIT
      , WARRANTEE_FLAG
      , VEND_NAME
      , VEND_SITE
      , BUYER_CODE
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
    FROM LOGIC_sitme21
)
---- FILTER LAYER ----

, FILTER_sitme21 as (
    SELECT *
    FROM RENAME_sitme21
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_sitme21
)

---- FINAL LAYER ----
SELECT
          LNK_SUPPLIER_ITEM_HK
        , VEND_CODE
        , PART_CODE
        , WARRANTEE_TYPE
        , ORIGIN_COUNTRY
        , LEAD_DAYS
        , YTD_ACTIVITY
        , MIN_ORD_QTY
        , PART_IDENT
        , PACK_QTY
        , PREF_FLG
        , VPART_DESC
        , CYCLE_TIME
        , LAST_TAG
        , LAST_ACTIVITY
        , WARRANTEE_PER
        , VEND_PART
        , DROP_SHIP
        , AGREEMENT_NO
        , YTD_PUR_UNIT
        , WARRANTEE_FLAG
        , VEND_NAME
        , VEND_SITE
        , BUYER_CODE
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
qualify 1 = row_number() over (partition by LNK_SUPPLIER_ITEM_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS LNK_SUPPLIER_ITEM_HK,
GR.VALUE::text AS VEND_CODE,
GR.VALUE::text AS PART_CODE,
NULL AS WARRANTEE_TYPE,
NULL AS ORIGIN_COUNTRY,
NULL AS LEAD_DAYS,
NULL AS YTD_ACTIVITY,
NULL AS MIN_ORD_QTY,
NULL AS PART_IDENT,
NULL AS PACK_QTY,
NULL AS PREF_FLG,
NULL AS VPART_DESC,
NULL AS CYCLE_TIME,
NULL AS LAST_TAG,
NULL AS LAST_ACTIVITY,
NULL AS WARRANTEE_PER,
NULL AS VEND_PART,
NULL AS DROP_SHIP,
NULL AS AGREEMENT_NO,
NULL AS YTD_PUR_UNIT,
NULL AS WARRANTEE_FLAG,
NULL AS VEND_NAME,
NULL AS VEND_SITE,
NULL AS BUYER_CODE,
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
