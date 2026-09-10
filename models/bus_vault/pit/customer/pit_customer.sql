---- SRC LAYER ----
WITH
SRC_H              as ( SELECT * FROM {{ ref('hub_customer_v1') }} as SRC  ),
SRC_SAT_WINN       as ( SELECT * FROM {{ ref('sat_customer__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CUSTOMER_HK ORDER BY LOAD_DTS DESC))=1 )

/*
SRC_H              as ( SELECT * FROM RAW_VAULT.hub_customer_v1 )
, SRC_SAT_WINN       as ( SELECT * FROM RAW_VAULT.sat_customer__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_H as (
    SELECT
        'PIT_CUSTOMER'                                                as                                         PIT_REC_SRC
      , CURRENT_DATE                                                 as                                       SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                        PIT_LOAD_DTS
      , CUSTOMER_HK
      , CUSTOMER_BK
      , REC_SRC
      , BKCC
    FROM SRC_H
)

, LOGIC_SAT_WINN as (
    SELECT
        CUSTOMER_HK                                                  as                               SAT_WINN_CUSTOMER_HK
      , NAME1
      , ORT01
      , DUNS
      , NAME2
      , FITYP
      , GFORM
      , KUKLA
      , PSA_DELETE_IND                                               as                            SAT_WINN_PSA_DELETE_IND
      , KTOKD
      , BRSCH
      , REGIO
      , PSTLZ
      , FISKN
    FROM SRC_SAT_WINN
)
---- RENAME LAYER ----

, RENAME_H as (
    SELECT
        PIT_REC_SRC
      , SNAPSHOTDATE
      , PIT_LOAD_DTS
      , CUSTOMER_HK
      , CUSTOMER_BK
      , REC_SRC
      , BKCC
    FROM LOGIC_H
)

, RENAME_SAT_WINN as (
    SELECT
        SAT_WINN_CUSTOMER_HK
      , NAME1
      , ORT01
      , DUNS
      , NAME2
      , FITYP
      , GFORM
      , KUKLA
      , SAT_WINN_PSA_DELETE_IND
      , KTOKD
      , BRSCH
      , REGIO
      , PSTLZ
      , FISKN
    FROM LOGIC_SAT_WINN
)
---- FILTER LAYER ----

, FILTER_H as (
    SELECT *
    FROM RENAME_H
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'  /* This filter is to exclude the ghost records */
  
)

, FILTER_SAT_WINN as (
    SELECT *
    FROM RENAME_SAT_WINN
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_H
    INNER JOIN FILTER_SAT_WINN
        ON FILTER_H.CUSTOMER_HK = SAT_WINN_CUSTOMER_HK
)

---- FINAL LAYER ----
SELECT
          PIT_REC_SRC
        , SNAPSHOTDATE
        , PIT_LOAD_DTS
        , CUSTOMER_HK
        , CUSTOMER_BK
        , CASE BKCC WHEN 'Hiding_Tiger' THEN NAME1
            END     as CUSTOMER_NAME_1
        , CASE BKCC WHEN 'Hiding_Tiger' THEN NAME2
            END     as CUSTOMER_NAME_2
        , CASE  WHEN BKCC = 'Hiding_Tiger' THEN ORT01
            END  as CITY
        , CASE BKCC WHEN 'Hiding_Tiger' THEN PSTLZ
            END     as POSTAL_CODE
        , CASE  WHEN BKCC = 'Hiding_Tiger' THEN REGIO
            END  as REGION
        , CASE  WHEN BKCC = 'Hiding_Tiger' THEN BRSCH
            END  as INDUSTRY_CODE
        , CASE  WHEN BKCC = 'Hiding_Tiger' THEN FISKN
            END  as PRIMARY_ACCOUNT_NUMBER
        , CASE  WHEN BKCC= 'Hiding_Tiger' THEN KTOKD
            END   as CUSTOMER_ACCOUNT_GROUP
        , CASE  WHEN BKCC = 'Hiding_Tiger' THEN KUKLA
            END  as CUSTOMER_CLASSIFICATION
        , CASE WHEN BKCC = 'Hiding_Tiger' THEN GFORM
            END   as LEGAL_STATUS
        , CASE  WHEN BKCC = 'Hiding_Tiger' THEN FITYP
            END  as TAX_TYPE
        , CASE  WHEN BKCC = 'Hiding_Tiger' THEN DUNS
            END   as DUNS_NUMBER
        , CASE  WHEN BKCC = 'Hiding_Tiger' THEN SAT_WINN_PSA_DELETE_IND
            END   as IS_DELETED            
        , REC_SRC
        , BKCC
FROM JOIN_RESULT
