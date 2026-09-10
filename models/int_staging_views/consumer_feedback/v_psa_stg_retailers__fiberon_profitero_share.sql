---- SRC LAYER ----
WITH
SRC_S1             as ( SELECT COUNTRY, DIM_RETAILER_KEY, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, RETAILER_ALIAS, RETAILER_NAME, UPDATED_AT
                              /* Within the same (BK, PSA_LOAD_DTS) partition, if a non-delete row exists alongside a delete, the delete is a truncate-reload artifact.
                                 True business deletes are safe, they have no companion INSERT in the same batch.
                              */
                              , CASE WHEN PSA_DELETE_IND = 'Y'
                                     AND COUNT_IF(PSA_DELETE_IND = 'N') OVER (PARTITION BY DIM_RETAILER_KEY, PSA_LOAD_DTS) > 0
                                     THEN TRUE ELSE FALSE END AS TRUNCATE_RELOAD_FLAG
                        FROM {{ source('profitero_share_fiberon', 'dim_retailer') }} as SRC
                        QUALIFY NOT TRUNCATE_RELOAD_FLAG ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S1             as ( SELECT * FROM profitero_share_fiberon.dim_retailer )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S1 as (
    SELECT
        RETAILER_NAME                                                as                                        RETAILER_BK
      /* PSA_LOAD_DTS for deletes (clears watermark), UPDATED_AT for active records (preserves business chronology) */
      , CONVERT_TIMEZONE('UTC', IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, UPDATED_AT)) as                                           LOAD_DTS
      , DIM_RETAILER_KEY
      , COUNTRY
      , UPDATED_AT
      , NULL                                                         as                                         IS_DELETED /* just to match cols from the old Profitero. This col is not being used in business_vault or infomart */
      , RETAILER_ALIAS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_S1
)

, LOGIC_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A1
)
---- RENAME LAYER ----

, RENAME_S1 as (
    SELECT
        RETAILER_BK
      , LOAD_DTS
      , DIM_RETAILER_KEY
      , COUNTRY
      , UPDATED_AT
      , IS_DELETED
      , RETAILER_ALIAS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_S1
)

, RENAME_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A1
)
---- FILTER LAYER ----

, FILTER_S1 as (
    SELECT *
    FROM RENAME_S1
)

, FILTER_A1 as (
    SELECT *
    FROM RENAME_A1
    WHERE rec_src = 'US.PROFITERO_FIBERON.RETAILERS'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S1
    INNER JOIN FILTER_A1
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          RETAILER_BK
        , LOAD_DTS
        , DIM_RETAILER_KEY
        , COUNTRY
        , UPDATED_AT
        , IS_DELETED
        , RETAILER_ALIAS
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(RETAILER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as RETAILER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(DIM_RETAILER_KEY::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(IS_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(RETAILER_ALIAS::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT