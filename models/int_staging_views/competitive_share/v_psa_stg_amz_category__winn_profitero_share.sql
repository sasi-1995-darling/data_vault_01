---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ source('profitero_share_moen', 'dim_amz_category') }} as SRC  
                        -- DEDUP: this is intentional exact-row dedup, NOT business-key dedup — partition on the ENTIRE row (all descriptive attrs) to collapse exact-duplicate reloads from the source. Earliest PSA load wins on true attribute change; identical payloads reduce to one row. 
                        qualify row_number() over(partition by AMZ_CATEGORY_ID, AMZ_CATEGORY_NAME, AMZ_CATEGORY_TYPE,CREATED_AT, UPDATED_AT order by psa_delete_ind, psa_load_dts)=1 ),
SRC_ref_bkcc       as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC 
                        WHERE rec_src = 'US.PROFITERO_SHARE_MOEN.DIM_AMZ_CATEGORY' )

/*
SRC_SRC            as ( SELECT * FROM profitero_share_moen.dim_amz_category )
SRC_ref_bkcc       as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        COALESCE(AMZ_CATEGORY_ID::TEXT, '-1')                        as                                    SNS_CATEGORY_BK
      , AMZ_CATEGORY_ID
      , DIM_AMZ_CATEGORY_KEY
      , AMZ_CATEGORY_NAME
      , AMZ_CATEGORY_TYPE
      , CREATED_AT
      , UPDATED_AT
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, coalesce(UPDATED_AT, PSA_LOAD_DTS))) as                                           LOAD_DTS
    FROM SRC_SRC
)

, LOGIC_ref_bkcc as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_ref_bkcc
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM LOGIC_SRC
    INNER JOIN LOGIC_ref_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          SNS_CATEGORY_BK
        , AMZ_CATEGORY_ID
        , DIM_AMZ_CATEGORY_KEY
        , AMZ_CATEGORY_NAME
        , AMZ_CATEGORY_TYPE
        , CREATED_AT
        , UPDATED_AT
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , BKCC
        , REC_SRC
        , LOAD_DTS
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(AMZ_CATEGORY_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SNS_CATEGORY_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(DIM_AMZ_CATEGORY_KEY::text), '^^') 
            , '||', IFNULL(TRIM(AMZ_CATEGORY_NAME::text), '^^') 
            , '||', IFNULL(TRIM(AMZ_CATEGORY_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(UPDATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
