---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ source('rgm_promotion', 'predicted') }} as SRC  ),
SRC_ref_bkcc       as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC 
                        WHERE rec_src = 'FBIN.DATASCIENCE.RGM_PROMO.PREDICTED' )

/*
SRC_SRC            as ( SELECT * FROM rgm_promotion.predicted )
SRC_ref_bkcc       as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        DIM_PROMOTION_KEY                                            as                               DIM_PROMOTION_KEY_BK
      , DIM_PROMOTION_KEY
      , ASOF
      , FINAL_BETA
      , QTY_WITHOUT_PROMO
      , QTY_WITH_PROMO
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
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
          DIM_PROMOTION_KEY_BK
        , DIM_PROMOTION_KEY
        , ASOF
        , FINAL_BETA
        , QTY_WITHOUT_PROMO
        , QTY_WITH_PROMO
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , BKCC
        , REC_SRC
        , LOAD_DTS
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DIM_PROMOTION_KEY as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DIM_PROMOTION_KEY_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ASOF::text), '^^') 
            , '||', IFNULL(TRIM(FINAL_BETA::text), '^^') 
            , '||', IFNULL(TRIM(QTY_WITHOUT_PROMO::text), '^^') 
            , '||', IFNULL(TRIM(QTY_WITH_PROMO::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
