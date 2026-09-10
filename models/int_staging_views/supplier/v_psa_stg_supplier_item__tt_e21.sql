---- SRC LAYER ----
WITH
SRC_S              as ( SELECT AGREEMENT_NO, BUYER_CODE, CYCLE_TIME, DROP_SHIP, LAST_ACTIVITY, LAST_TAG, LEAD_DAYS, MIN_ORD_QTY, ORIGIN_COUNTRY, PACK_QTY, PART_CODE, PART_IDENT, PREF_FLG, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, VEND_CODE, VEND_NAME, VEND_PART, VEND_SITE, VPART_DESC, WARRANTEE_FLAG, WARRANTEE_PER, WARRANTEE_TYPE, YTD_ACTIVITY, YTD_PUR_UNIT, _FIVETRAN_DELETED, _FIVETRAN_ID, _FIVETRAN_SYNCED FROM {{ source('tt_e21prd_e21trubis', 'vendpart') }} as SRC 
                        /* The filter ensures that duplicate records with trailing spaces in the part_code field are removed from the source system */
                        qualify 1= row_number() over(partition by  TRIM(CAST(VEND_CODE as VARCHAR)),TRIM(CAST(part_code as VARCHAR)), _fivetran_synced order by  _fivetran_synced desc, length(part_code)) ),
SRC_A              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM tt_e21prd_e21trubis.vendpart )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        VEND_CODE
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
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
    FROM SRC_S
)

, LOGIC_A as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        VEND_CODE
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
    FROM LOGIC_S
)

, RENAME_A as (
    SELECT
        BKCC
      , REC_SRC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USOHMA.ORCL.E21PRD.VENDPART'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          VEND_CODE
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
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VEND_CODE as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PART_CODE as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VEND_CODE as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PART_CODE as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_SUPPLIER_ITEM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(PART_CODE::text), '^^') 
            , '||', IFNULL(TRIM(LEAD_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(YTD_ACTIVITY::text), '^^') 
            , '||', IFNULL(TRIM(MIN_ORD_QTY::text), '^^') 
            , '||', IFNULL(TRIM(PART_IDENT::text), '^^') 
            , '||', IFNULL(TRIM(PACK_QTY::text), '^^') 
            , '||', IFNULL(TRIM(PREF_FLG::text), '^^') 
            , '||', IFNULL(TRIM(VPART_DESC::text), '^^') 
            , '||', IFNULL(TRIM(CYCLE_TIME::text), '^^') 
            , '||', IFNULL(TRIM(LAST_TAG::text), '^^') 
            , '||', IFNULL(TRIM(LAST_ACTIVITY::text), '^^') 
            , '||', IFNULL(TRIM(WARRANTEE_PER::text), '^^') 
            , '||', IFNULL(TRIM(VEND_PART::text), '^^') 
            , '||', IFNULL(TRIM(DROP_SHIP::text), '^^') 
            , '||', IFNULL(TRIM(AGREEMENT_NO::text), '^^') 
            , '||', IFNULL(TRIM(YTD_PUR_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(WARRANTEE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(VEND_NAME::text), '^^') 
            , '||', IFNULL(TRIM(VEND_SITE::text), '^^') 
            , '||', IFNULL(TRIM(BUYER_CODE::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
