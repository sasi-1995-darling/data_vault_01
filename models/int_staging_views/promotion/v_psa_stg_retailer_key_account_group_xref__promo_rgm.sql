---- SRC LAYER ----
WITH
SRC_xref           as ( SELECT ERP_KEY_ACCOUNT_GROUP, ERP_REC_SRC, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, RETAILER, RETAILER_KEY_ACCOUNT_GROUP, RETAILER_REC_SRC, _FILE, _FIVETRAN_SYNCED, _LINE, _MODIFIED FROM {{ source('rgm_promotion', 'retailer_key_account_group_xref') }} as SRC 
                        /*excludes retailers for which we do not currently have data for in pos and therefore cannot establish a relationship for*/
                        WHERE RETAILER_REC_SRC IS NOT NULL ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_retailer_bkcc  as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_erp_bkcc       as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_xref           as ( SELECT * FROM rgm_promotion.retailer_key_account_group_xref )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_retailer_bkcc  as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_erp_bkcc       as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_xref as (
    SELECT
        _FILE
      , _LINE
      , _MODIFIED
      , _FIVETRAN_SYNCED
      , RETAILER_REC_SRC
      , RETAILER_KEY_ACCOUNT_GROUP
      , RETAILER
      , ERP_KEY_ACCOUNT_GROUP
      , ERP_REC_SRC
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , IFF(
            PSA_DELETE_IND = 'Y',
        PSA_LOAD_DTS, CONVERT_TIMEZONE('UTC',_FIVETRAN_SYNCED))      as                                           LOAD_DTS
    FROM SRC_xref
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)

, LOGIC_retailer_bkcc as (
    SELECT
        BKCC                                                         as                                      RETAILER_BKCC
      , REC_SRC                                                      as                              RETAILER_BKCC_REC_SRC
    FROM SRC_retailer_bkcc
)

, LOGIC_erp_bkcc as (
    SELECT
        BKCC                                                         as                                           ERP_BKCC
      , REC_SRC                                                      as                                   ERP_BKCC_REC_SRC
    FROM SRC_erp_bkcc
)
---- RENAME LAYER ----

, RENAME_xref as (
    SELECT
        _FILE
      , _LINE
      , _MODIFIED
      , _FIVETRAN_SYNCED
      , RETAILER_REC_SRC
      , RETAILER_KEY_ACCOUNT_GROUP
      , RETAILER
      , ERP_KEY_ACCOUNT_GROUP
      , ERP_REC_SRC
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_xref
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)

, RENAME_retailer_bkcc as (
    SELECT
        RETAILER_BKCC
      , RETAILER_BKCC_REC_SRC
    FROM LOGIC_retailer_bkcc
)

, RENAME_erp_bkcc as (
    SELECT
        ERP_BKCC
      , ERP_BKCC_REC_SRC
    FROM LOGIC_erp_bkcc
)
---- FILTER LAYER ----

, FILTER_xref as (
    SELECT *
    FROM RENAME_xref
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'US.EXCEL.RGM_PROMO.RETAILER_KEY_ACCOUNT_GROUP_XREF'
)

, FILTER_retailer_bkcc as (
    SELECT *
    FROM RENAME_retailer_bkcc
)

, FILTER_erp_bkcc as (
    SELECT *
    FROM RENAME_erp_bkcc
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_xref
    INNER JOIN FILTER_a
        ON '1' = '1'
    LEFT JOIN FILTER_retailer_bkcc
        ON retailer_rec_src = retailer_bkcc_rec_src
    LEFT JOIN FILTER_erp_bkcc
        ON erp_rec_src = erp_bkcc_rec_src
)

---- FINAL LAYER ----
SELECT
          COALESCE(NULLIF(UPPER(TRIM(RETAILER_KEY_ACCOUNT_GROUP)),''),'-1') as RETAILER_KEY_ACCOUNT_GROUP_BK
        , COALESCE(NULLIF(UPPER(TRIM(ERP_KEY_ACCOUNT_GROUP)),''),'-1') as ERP_KEY_ACCOUNT_GROUP_BK
        , _FILE
        , _LINE
        , _MODIFIED
        , _FIVETRAN_SYNCED
        , RETAILER_REC_SRC
        , RETAILER_KEY_ACCOUNT_GROUP
        , RETAILER
        , ERP_KEY_ACCOUNT_GROUP
        , ERP_REC_SRC
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , RETAILER_BKCC
        , ERP_BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(RETAILER_KEY_ACCOUNT_GROUP_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(RETAILER_BKCC as VARCHAR)),''), '^^')
        ))) as KEY_ACCOUNT_GROUP_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ERP_KEY_ACCOUNT_GROUP_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ERP_BKCC as VARCHAR)),''), '^^')
        ))) as SAME_AS_KEY_ACCOUNT_GROUP_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(RETAILER_KEY_ACCOUNT_GROUP_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ERP_KEY_ACCOUNT_GROUP_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(RETAILER_BKCC as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ERP_BKCC as VARCHAR)),''), '^^')
        ))) as SLNK_KEY_ACCOUNT_GROUP_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(_FILE::text), '^^') 
            , '||', IFNULL(TRIM(_LINE::text), '^^') 
            , '||', IFNULL(TRIM(_MODIFIED::text), '^^') 
            , '||', IFNULL(TRIM(RETAILER_REC_SRC::text), '^^') 
            , '||', IFNULL(TRIM(RETAILER_KEY_ACCOUNT_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(RETAILER::text), '^^') 
            , '||', IFNULL(TRIM(ERP_KEY_ACCOUNT_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(ERP_REC_SRC::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
