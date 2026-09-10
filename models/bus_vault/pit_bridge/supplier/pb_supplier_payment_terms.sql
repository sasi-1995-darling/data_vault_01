---- SRC LAYER ----
WITH
SRC_winn           as ( SELECT BKCC, CURRENCY_CODE, END_DATE__YYYYMMDD, IS_DELETED, PAYMENT_TERM_BK, PAYMENT_TERM_CODE, PAYMENT_TERM_DESC, PAYMENT_TERM_DUE_DAYS, PAYMENT_TERM_HK, PURCHASING_ORG_BK, PURCHASING_ORG_HK, REC_SRC, START_DATE__YYYYMMDD, SUPPLIER_BK, SUPPLIER_HK, SUPPLIER_PAYMENT_TERM_DURABLE_HK, SUPPLIER_PAYMENT_TERM_HK, SUPPLIER_PURCHASING_ORG_STATUS FROM {{ ref('stg_pb_supplier_payment_terms__winn_sap') }} as SRC  ),
SRC_tmlc           as ( SELECT BKCC, CURRENCY_CODE, DISCOUNT_DAYS, DISCOUNT_PERCENT, END_DATE__YYYYMMDD, IS_DELETED, PAYMENT_TERM_BK, PAYMENT_TERM_CODE, PAYMENT_TERM_DESC, PAYMENT_TERM_DUE_DAYS, PAYMENT_TERM_HK, REC_SRC, START_DATE__YYYYMMDD, SUPPLIER_BK, SUPPLIER_HK, SUPPLIER_PAYMENT_TERM_DURABLE_HK, SUPPLIER_PAYMENT_TERM_HK, SUPPLIER_SITE_BK, SUPPLIER_SITE_HK FROM {{ ref('stg_pb_supplier_payment_terms__ml_ebs') }} as SRC  ),
SRC_emtk           as ( SELECT BKCC, CURRENCY_CODE, DISCOUNT_DAYS, DISCOUNT_PERCENT, END_DATE__YYYYMMDD, IS_DELETED, PAYMENT_TERM_BK, PAYMENT_TERM_CODE, PAYMENT_TERM_DESC, PAYMENT_TERM_DUE_DAYS, PAYMENT_TERM_HK, REC_SRC, START_DATE__YYYYMMDD, SUPPLIER_BK, SUPPLIER_HK, SUPPLIER_PAYMENT_TERM_DURABLE_HK, SUPPLIER_PAYMENT_TERM_HK, SUPPLIER_SITE_BK, SUPPLIER_SITE_HK FROM {{ ref('stg_pb_supplier_payment_terms__emtk_ebs') }} as SRC  ),
SRC_fib            as ( SELECT BKCC, CURRENCY_CODE, DISCOUNT_DAYS, DISCOUNT_PERCENT, END_DATE__YYYYMMDD, IS_DELETED, PAYMENT_TERM_BK, PAYMENT_TERM_CODE, PAYMENT_TERM_DESC, PAYMENT_TERM_DUE_DAYS, PAYMENT_TERM_HK, REC_SRC, START_DATE__YYYYMMDD, SUPPLIER_BK, SUPPLIER_HK, SUPPLIER_PAYMENT_TERM_DURABLE_HK, SUPPLIER_PAYMENT_TERM_HK, SUPPLIER_SITE_BK, SUPPLIER_SITE_HK FROM {{ ref('stg_pb_supplier_payment_terms__fib_ocf') }} as SRC  ),
SRC_tt             as ( SELECT BKCC, DISCOUNT_DAYS, DISCOUNT_PERCENT, END_DATE__YYYYMMDD, IS_DELETED, PAYMENT_TERM_BK, PAYMENT_TERM_CODE, PAYMENT_TERM_DESC, PAYMENT_TERM_DUE_DAYS, PAYMENT_TERM_HK, REC_SRC, START_DATE__YYYYMMDD, SUPPLIER_BK, SUPPLIER_HK, SUPPLIER_PAYMENT_TERM_DURABLE_HK, SUPPLIER_PAYMENT_TERM_HK FROM {{ ref('stg_pb_supplier_payment_terms__tt_e21_gp') }} as SRC  ),
SRC_larson         as ( SELECT BKCC, CURRENCY_CODE, DISCOUNT_DAYS, DISCOUNT_PERCENT, END_DATE__YYYYMMDD, IS_DELETED, PAYMENT_TERM_BK, PAYMENT_TERM_CODE, PAYMENT_TERM_DESC, PAYMENT_TERM_DUE_DAYS, PAYMENT_TERM_HK, REC_SRC, START_DATE__YYYYMMDD, SUPPLIER_BK, SUPPLIER_HK, SUPPLIER_PAYMENT_TERM_DURABLE_HK, SUPPLIER_PAYMENT_TERM_HK, SUPPLIER_SITE_BK, SUPPLIER_SITE_HK FROM {{ ref('stg_pb_supplier_payment_terms__lrsn_psft') }} as SRC  )

/*
SRC_winn           as ( SELECT * FROM BUS_VAULT.stg_pb_supplier_payment_terms__winn_sap )
SRC_tmlc           as ( SELECT * FROM BUS_VAULT.stg_pb_supplier_payment_terms__ml_ebs )
SRC_emtk           as ( SELECT * FROM BUS_VAULT.stg_pb_supplier_payment_terms__emtk_ebs )
SRC_fib            as ( SELECT * FROM BUS_VAULT.stg_pb_supplier_payment_terms__fib_ocf )
SRC_tt             as ( SELECT * FROM BUS_VAULT.stg_pb_supplier_payment_terms__tt_e21_gp )
SRC_larson         as ( SELECT * FROM BUS_VAULT.stg_pb_supplier_payment_terms__lrsn_psft )
*/
---- LOGIC LAYER ----

, LOGIC_winn as (
    SELECT
        SUPPLIER_BK
      , PURCHASING_ORG_BK
      , PAYMENT_TERM_BK
      , '-2'                                                         as                                   SUPPLIER_SITE_BK
      , START_DATE__YYYYMMDD
      , END_DATE__YYYYMMDD
      , PAYMENT_TERM_CODE
      , PAYMENT_TERM_DESC
      , PAYMENT_TERM_DUE_DAYS
      , NULL                                                         as                                      DISCOUNT_DAYS
      , NULL                                                         as                                   DISCOUNT_PERCENT
      , CURRENCY_CODE
      , SUPPLIER_PURCHASING_ORG_STATUS
      , IS_DELETED
      , CASE WHEN END_DATE__YYYYMMDD = '20991231' THEN 'Y' ELSE 'N' END as                                       CURRENT_FLAG
      , REC_SRC
      , BKCC
      , SUPPLIER_HK
      , PAYMENT_TERM_HK
      , PURCHASING_ORG_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
        )))                                                          as                                   SUPPLIER_SITE_HK
      , SUPPLIER_PAYMENT_TERM_HK
      , SUPPLIER_PAYMENT_TERM_DURABLE_HK
    FROM SRC_winn
)

, LOGIC_tmlc as (
    SELECT
        SUPPLIER_BK
      , '-2'                                                         as                                  PURCHASING_ORG_BK
      , PAYMENT_TERM_BK
      , SUPPLIER_SITE_BK
      , START_DATE__YYYYMMDD
      , END_DATE__YYYYMMDD
      , PAYMENT_TERM_CODE
      , PAYMENT_TERM_DESC
      , PAYMENT_TERM_DUE_DAYS
      , DISCOUNT_DAYS
      , DISCOUNT_PERCENT
      , CURRENCY_CODE
      , NULL                                                         as                     SUPPLIER_PURCHASING_ORG_STATUS
      , IS_DELETED
      , CASE WHEN END_DATE__YYYYMMDD = '20991231' THEN 'Y' ELSE 'N' END as                                       CURRENT_FLAG
      , REC_SRC
      , BKCC
      , SUPPLIER_HK
      , PAYMENT_TERM_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
        )))                                                          as                                  PURCHASING_ORG_HK
      , SUPPLIER_SITE_HK
      , SUPPLIER_PAYMENT_TERM_HK
      , SUPPLIER_PAYMENT_TERM_DURABLE_HK
    FROM SRC_tmlc
)

, LOGIC_emtk as (
    SELECT
        SUPPLIER_BK
      , '-2'                                                         as                                  PURCHASING_ORG_BK
      , PAYMENT_TERM_BK
      , SUPPLIER_SITE_BK
      , START_DATE__YYYYMMDD
      , END_DATE__YYYYMMDD
      , PAYMENT_TERM_CODE
      , PAYMENT_TERM_DESC
      , PAYMENT_TERM_DUE_DAYS
      , DISCOUNT_DAYS
      , DISCOUNT_PERCENT
      , CURRENCY_CODE
      , NULL                                                         as                     SUPPLIER_PURCHASING_ORG_STATUS
      , IS_DELETED
      , CASE WHEN END_DATE__YYYYMMDD = '20991231' THEN 'Y' ELSE 'N' END as                                       CURRENT_FLAG
      , REC_SRC
      , BKCC
      , SUPPLIER_HK
      , PAYMENT_TERM_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
        )))                                                          as                                  PURCHASING_ORG_HK
      , SUPPLIER_SITE_HK
      , SUPPLIER_PAYMENT_TERM_HK
      , SUPPLIER_PAYMENT_TERM_DURABLE_HK
    FROM SRC_emtk
)

, LOGIC_fib as (
    SELECT
        SUPPLIER_BK
      , '-2'                                                         as                                  PURCHASING_ORG_BK
      , PAYMENT_TERM_BK
      , SUPPLIER_SITE_BK
      , START_DATE__YYYYMMDD
      , END_DATE__YYYYMMDD
      , PAYMENT_TERM_CODE
      , PAYMENT_TERM_DESC
      , PAYMENT_TERM_DUE_DAYS
      , DISCOUNT_DAYS
      , DISCOUNT_PERCENT
      , CURRENCY_CODE
      , NULL                                                         as                     SUPPLIER_PURCHASING_ORG_STATUS
      , IS_DELETED
      , CASE WHEN END_DATE__YYYYMMDD = '20991231' THEN 'Y' ELSE 'N' END as                                       CURRENT_FLAG
      , REC_SRC
      , BKCC
      , SUPPLIER_HK
      , PAYMENT_TERM_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
        )))                                                          as                                  PURCHASING_ORG_HK
      , SUPPLIER_SITE_HK
      , SUPPLIER_PAYMENT_TERM_HK
      , SUPPLIER_PAYMENT_TERM_DURABLE_HK
    FROM SRC_fib
)

, LOGIC_tt as (
    SELECT
        SUPPLIER_BK
      , '-2'                                                         as                                  PURCHASING_ORG_BK
      , PAYMENT_TERM_BK
      , '-2'                                                         as                                   SUPPLIER_SITE_BK
      , START_DATE__YYYYMMDD
      , END_DATE__YYYYMMDD
      , PAYMENT_TERM_CODE
      , PAYMENT_TERM_DESC
      , PAYMENT_TERM_DUE_DAYS
      , DISCOUNT_DAYS
      , DISCOUNT_PERCENT
      , NULL                                                         as                                      CURRENCY_CODE
      , NULL                                                         as                     SUPPLIER_PURCHASING_ORG_STATUS
      , IS_DELETED
      , CASE WHEN END_DATE__YYYYMMDD = '20991231' THEN 'Y' ELSE 'N' END as                                       CURRENT_FLAG
      , REC_SRC
      , BKCC
      , SUPPLIER_HK
      , PAYMENT_TERM_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
        )))                                                          as                                  PURCHASING_ORG_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
        )))                                                          as                                   SUPPLIER_SITE_HK
      , SUPPLIER_PAYMENT_TERM_HK
      , SUPPLIER_PAYMENT_TERM_DURABLE_HK
    FROM SRC_tt
)

, LOGIC_larson as (
    SELECT
        SUPPLIER_BK
      , '-2'                                                         as                                  PURCHASING_ORG_BK
      , PAYMENT_TERM_BK
      , SUPPLIER_SITE_BK
      , START_DATE__YYYYMMDD
      , END_DATE__YYYYMMDD
      , PAYMENT_TERM_CODE
      , PAYMENT_TERM_DESC
      , PAYMENT_TERM_DUE_DAYS
      , DISCOUNT_DAYS
      , DISCOUNT_PERCENT
      , CURRENCY_CODE
      , NULL                                                         as                     SUPPLIER_PURCHASING_ORG_STATUS
      , IS_DELETED
      , CASE WHEN END_DATE__YYYYMMDD = '20991231' THEN 'Y' ELSE 'N' END as                                       CURRENT_FLAG
      , REC_SRC
      , BKCC
      , SUPPLIER_HK
      , PAYMENT_TERM_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
        )))                                                          as                                  PURCHASING_ORG_HK
      , SUPPLIER_SITE_HK
      , SUPPLIER_PAYMENT_TERM_HK
      , SUPPLIER_PAYMENT_TERM_DURABLE_HK
    FROM SRC_larson
)
---- RENAME LAYER ----

, RENAME_winn as (
    SELECT
        SUPPLIER_BK
      , PURCHASING_ORG_BK
      , PAYMENT_TERM_BK
      , SUPPLIER_SITE_BK
      , START_DATE__YYYYMMDD
      , END_DATE__YYYYMMDD
      , PAYMENT_TERM_CODE
      , PAYMENT_TERM_DESC
      , PAYMENT_TERM_DUE_DAYS
      , DISCOUNT_DAYS
      , DISCOUNT_PERCENT
      , CURRENCY_CODE
      , SUPPLIER_PURCHASING_ORG_STATUS
      , IS_DELETED
      , CURRENT_FLAG
      , REC_SRC
      , BKCC
      , SUPPLIER_HK
      , PAYMENT_TERM_HK
      , PURCHASING_ORG_HK
      , SUPPLIER_SITE_HK
      , SUPPLIER_PAYMENT_TERM_HK
      , SUPPLIER_PAYMENT_TERM_DURABLE_HK
    FROM LOGIC_winn
)

, RENAME_tmlc as (
    SELECT
        SUPPLIER_BK
      , PURCHASING_ORG_BK
      , PAYMENT_TERM_BK
      , SUPPLIER_SITE_BK
      , START_DATE__YYYYMMDD
      , END_DATE__YYYYMMDD
      , PAYMENT_TERM_CODE
      , PAYMENT_TERM_DESC
      , PAYMENT_TERM_DUE_DAYS
      , DISCOUNT_DAYS
      , DISCOUNT_PERCENT
      , CURRENCY_CODE
      , SUPPLIER_PURCHASING_ORG_STATUS
      , IS_DELETED
      , CURRENT_FLAG
      , REC_SRC
      , BKCC
      , SUPPLIER_HK
      , PAYMENT_TERM_HK
      , PURCHASING_ORG_HK
      , SUPPLIER_SITE_HK
      , SUPPLIER_PAYMENT_TERM_HK
      , SUPPLIER_PAYMENT_TERM_DURABLE_HK
    FROM LOGIC_tmlc
)

, RENAME_emtk as (
    SELECT
        SUPPLIER_BK
      , PURCHASING_ORG_BK
      , PAYMENT_TERM_BK
      , SUPPLIER_SITE_BK
      , START_DATE__YYYYMMDD
      , END_DATE__YYYYMMDD
      , PAYMENT_TERM_CODE
      , PAYMENT_TERM_DESC
      , PAYMENT_TERM_DUE_DAYS
      , DISCOUNT_DAYS
      , DISCOUNT_PERCENT
      , CURRENCY_CODE
      , SUPPLIER_PURCHASING_ORG_STATUS
      , IS_DELETED
      , CURRENT_FLAG
      , REC_SRC
      , BKCC
      , SUPPLIER_HK
      , PAYMENT_TERM_HK
      , PURCHASING_ORG_HK
      , SUPPLIER_SITE_HK
      , SUPPLIER_PAYMENT_TERM_HK
      , SUPPLIER_PAYMENT_TERM_DURABLE_HK
    FROM LOGIC_emtk
)

, RENAME_fib as (
    SELECT
        SUPPLIER_BK
      , PURCHASING_ORG_BK
      , PAYMENT_TERM_BK
      , SUPPLIER_SITE_BK
      , START_DATE__YYYYMMDD
      , END_DATE__YYYYMMDD
      , PAYMENT_TERM_CODE
      , PAYMENT_TERM_DESC
      , PAYMENT_TERM_DUE_DAYS
      , DISCOUNT_DAYS
      , DISCOUNT_PERCENT
      , CURRENCY_CODE
      , SUPPLIER_PURCHASING_ORG_STATUS
      , IS_DELETED
      , CURRENT_FLAG
      , REC_SRC
      , BKCC
      , SUPPLIER_HK
      , PAYMENT_TERM_HK
      , PURCHASING_ORG_HK
      , SUPPLIER_SITE_HK
      , SUPPLIER_PAYMENT_TERM_HK
      , SUPPLIER_PAYMENT_TERM_DURABLE_HK
    FROM LOGIC_fib
)

, RENAME_tt as (
    SELECT
        SUPPLIER_BK
      , PURCHASING_ORG_BK
      , PAYMENT_TERM_BK
      , SUPPLIER_SITE_BK
      , START_DATE__YYYYMMDD
      , END_DATE__YYYYMMDD
      , PAYMENT_TERM_CODE
      , PAYMENT_TERM_DESC
      , PAYMENT_TERM_DUE_DAYS
      , DISCOUNT_DAYS
      , DISCOUNT_PERCENT
      , CURRENCY_CODE
      , SUPPLIER_PURCHASING_ORG_STATUS
      , IS_DELETED
      , CURRENT_FLAG
      , REC_SRC
      , BKCC
      , SUPPLIER_HK
      , PAYMENT_TERM_HK
      , PURCHASING_ORG_HK
      , SUPPLIER_SITE_HK
      , SUPPLIER_PAYMENT_TERM_HK
      , SUPPLIER_PAYMENT_TERM_DURABLE_HK
    FROM LOGIC_tt
)

, RENAME_larson as (
    SELECT
        SUPPLIER_BK
      , PURCHASING_ORG_BK
      , PAYMENT_TERM_BK
      , SUPPLIER_SITE_BK
      , START_DATE__YYYYMMDD
      , END_DATE__YYYYMMDD
      , PAYMENT_TERM_CODE
      , PAYMENT_TERM_DESC
      , PAYMENT_TERM_DUE_DAYS
      , DISCOUNT_DAYS
      , DISCOUNT_PERCENT
      , CURRENCY_CODE
      , SUPPLIER_PURCHASING_ORG_STATUS
      , IS_DELETED
      , CURRENT_FLAG
      , REC_SRC
      , BKCC
      , SUPPLIER_HK
      , PAYMENT_TERM_HK
      , PURCHASING_ORG_HK
      , SUPPLIER_SITE_HK
      , SUPPLIER_PAYMENT_TERM_HK
      , SUPPLIER_PAYMENT_TERM_DURABLE_HK
    FROM LOGIC_larson
)
---- FILTER LAYER ----

, FILTER_winn as (
    SELECT *
    FROM RENAME_winn
)

, FILTER_tmlc as (
    SELECT *
    FROM RENAME_tmlc
)

, FILTER_emtk as (
    SELECT *
    FROM RENAME_emtk
)

, FILTER_fib as (
    SELECT *
    FROM RENAME_fib
)

, FILTER_tt as (
    SELECT *
    FROM RENAME_tt
)

, FILTER_larson as (
    SELECT *
    FROM RENAME_larson
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_winn
    UNION ALL
    SELECT * FROM FILTER_tmlc
    UNION ALL
    SELECT * FROM FILTER_emtk
    UNION ALL
    SELECT * FROM FILTER_fib
    UNION ALL
    SELECT * FROM FILTER_tt
    UNION ALL
    SELECT * FROM FILTER_larson
)

---- FINAL LAYER ----
SELECT
          'PB_SUPPLIER'                                                as PB_REC_SRC
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PB_LOAD_DTS
        , SUPPLIER_BK
        , PURCHASING_ORG_BK
        , PAYMENT_TERM_BK
        , SUPPLIER_SITE_BK
        , START_DATE__YYYYMMDD
        , END_DATE__YYYYMMDD
        , PAYMENT_TERM_CODE
        , PAYMENT_TERM_DESC
        , PAYMENT_TERM_DUE_DAYS
        , DISCOUNT_DAYS
        , DISCOUNT_PERCENT
        , CURRENCY_CODE
        , SUPPLIER_PURCHASING_ORG_STATUS
        , IS_DELETED
        , CURRENT_FLAG
        , REC_SRC
        , BKCC
        , SUPPLIER_HK
        , PAYMENT_TERM_HK
        , PURCHASING_ORG_HK
        , SUPPLIER_SITE_HK
        , SUPPLIER_PAYMENT_TERM_HK
        , SUPPLIER_PAYMENT_TERM_DURABLE_HK
FROM JOIN_RESULT
