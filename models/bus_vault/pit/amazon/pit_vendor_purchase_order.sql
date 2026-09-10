---- SRC LAYER ----
WITH
SRC_HV             as ( SELECT BKCC, REC_SRC, VENDOR_ORDER_BK, VENDOR_ORDER_HK FROM {{ ref('hub_vendor_order') }} as SRC  ),
SRC_SV             as ( SELECT PAYMENT_METHOD, PSA_DELETE_IND, PURCHASE_ORDER_DATE, PURCHASE_ORDER_NUMBER, PURCHASE_ORDER_STATE, PURCHASE_ORDER_TYPE, VENDOR_ORDER_HK FROM {{ ref('sat_vendor_order__amazon') }} as SRC 
                        qualify 1= row_number() over(partition by VENDOR_ORDER_HK order by LOAD_DTS DESC) ),
SRC_SVS            as ( SELECT PURCHASE_ORDER_STATUS, VENDOR_ORDER_HK FROM {{ ref('sat_vendor_order_status__amazon') }} as SRC 
                        qualify 1= row_number() over(partition by VENDOR_ORDER_HK order by LOAD_DTS DESC) )

/*
SRC_HV             as ( SELECT * FROM RAW_VAULT.HUB_VENDOR_ORDER )
SRC_SV             as ( SELECT * FROM RAW_VAULT.SAT_VENDOR_ORDER__AMAZON )
SRC_SVS            as ( SELECT * FROM RAW_VAULT.SAT_VENDOR_ORDER_STATUS__AMAZON )
*/
---- LOGIC LAYER ----

, LOGIC_HV as (
    SELECT
        CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP ) as PIT_LOAD_DTS
      , BKCC
      , 'PIT_VENDOR_ORDER' as PIT_REC_SRC
      , REC_SRC
      , VENDOR_ORDER_BK
      , VENDOR_ORDER_HK
    FROM SRC_HV
)

, LOGIC_SV as (
    SELECT
        VENDOR_ORDER_HK                                              as                                 SV_VENDOR_ORDER_HK
      , PURCHASE_ORDER_STATE                                         as                                    VENDOR_PO_STATE
      , PURCHASE_ORDER_NUMBER                                        as                                   VENDOR_PO_NUMBER
      , PURCHASE_ORDER_TYPE                                          as                                     VENDOR_PO_TYPE
      , PAYMENT_METHOD
      , PURCHASE_ORDER_DATE                                          as                                     VENDOR_PO_DATE
      , PSA_DELETE_IND                                               as                            SAT_WINN_PSA_DELETE_IND
    FROM SRC_SV
)

, LOGIC_SVS as (
    SELECT
        VENDOR_ORDER_HK                                              as                                SVS_VENDOR_ORDER_HK
      , PURCHASE_ORDER_STATUS                                        as                                   VENDOR_PO_STATUS
    FROM SRC_SVS
)
---- RENAME LAYER ----

, RENAME_HV as (
    SELECT
        PIT_LOAD_DTS
      , BKCC
      , PIT_REC_SRC
      , REC_SRC
      , VENDOR_ORDER_BK
      , VENDOR_ORDER_HK
    FROM LOGIC_HV
)

, RENAME_SV as (
    SELECT
        SV_VENDOR_ORDER_HK
      , VENDOR_PO_STATE
      , VENDOR_PO_NUMBER
      , VENDOR_PO_TYPE
      , PAYMENT_METHOD
      , VENDOR_PO_DATE
      , SAT_WINN_PSA_DELETE_IND
    FROM LOGIC_SV
)

, RENAME_SVS as (
    SELECT
        SVS_VENDOR_ORDER_HK
      , VENDOR_PO_STATUS
    FROM LOGIC_SVS
)
---- FILTER LAYER ----

, FILTER_HV as (
    SELECT *
    FROM RENAME_HV
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'  /* This filter is to exclude the ghost records */
)

, FILTER_SV as (
    SELECT *
    FROM RENAME_SV
)

, FILTER_SVS as (
    SELECT *
    FROM RENAME_SVS
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HV
    INNER JOIN FILTER_SV
        ON FILTER_HV.VENDOR_ORDER_HK = FILTER_SV.SV_VENDOR_ORDER_HK
    LEFT JOIN FILTER_SVS
        ON FILTER_HV.VENDOR_ORDER_HK = FILTER_SVS.SVS_VENDOR_ORDER_HK
)

---- FINAL LAYER ----
SELECT
          row_number() over(order by 1)                                as SEQ_ID
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , PIT_LOAD_DTS
        , BKCC
        , PIT_REC_SRC
        , REC_SRC
        , VENDOR_ORDER_BK
        , VENDOR_ORDER_HK
        , VENDOR_PO_STATE
        , VENDOR_PO_NUMBER
        , VENDOR_PO_TYPE
        , PAYMENT_METHOD
        , CAST(TO_CHAR(VENDOR_PO_DATE, 'YYYYMMDD') AS INTEGER) as VENDOR_PO_DATE__YYYYMMDD
        , VENDOR_PO_STATUS
        , CASE BKCC WHEN 'Running_Horse' THEN SAT_WINN_PSA_DELETE_IND
    END as IS_DELETED
FROM JOIN_RESULT
