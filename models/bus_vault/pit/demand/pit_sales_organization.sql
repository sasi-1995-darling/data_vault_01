---- SRC LAYER ----
WITH
SRC_H              as ( SELECT * FROM {{ ref('hub_sales_organization') }} as SRC  ),
SRC_SAT_WINN       as ( SELECT SALES_ORGANIZATION_HK
                             , PSA_DELETE_IND                                               
                             , SPRAS                                                        
                             , VKORG                                                       
                             , VTEXT 
                        FROM {{ ref('sat_sales_organization__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SALES_ORGANIZATION_HK, SPRAS  ORDER BY LOAD_DTS DESC))=1 )

/*
SRC_H              as ( SELECT * FROM RAW_VAULT.hub_sales_organization )
, SRC_SAT_WINN       as ( SELECT * FROM RAW_VAULT.sat_sales_organization__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_H as (
    SELECT
        'PIT_SALES_ORGANIZATION'                                     as                                         PIT_REC_SRC
      , CURRENT_DATE                                                 as                                         SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                         PIT_LOAD_DTS
      , SALES_ORGANIZATION_HK
      , SALES_ORGANIZATION_BK
      , REC_SRC
      , BKCC
    FROM SRC_H
)

, LOGIC_SAT_WINN as (
    SELECT
        SALES_ORGANIZATION_HK                                        as SAT_WINN_SALES_ORGANIZATION_HK
      , PSA_DELETE_IND                                               as SAT_WINN_PSA_DELETE_IND
      , SPRAS                                                        as LANGUAGE_KEY
      , VKORG                                                        as SALES_ORGANIZATION
      , VTEXT                                                        as SALES_ORGANIZATION_NAME
    FROM SRC_SAT_WINN
)
---- RENAME LAYER ----

, RENAME_H as (
    SELECT
        PIT_REC_SRC
      , SNAPSHOTDATE
      , PIT_LOAD_DTS
      , SALES_ORGANIZATION_HK
      , SALES_ORGANIZATION_BK
      , REC_SRC
      , BKCC
    FROM LOGIC_H
)

, RENAME_SAT_WINN as (
    SELECT
        SAT_WINN_SALES_ORGANIZATION_HK
      , SAT_WINN_PSA_DELETE_IND
      , LANGUAGE_KEY
      , SALES_ORGANIZATION
      , SALES_ORGANIZATION_NAME
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
    inner JOIN FILTER_SAT_WINN
        ON FILTER_H.SALES_ORGANIZATION_HK = SAT_WINN_SALES_ORGANIZATION_HK
)

---- FINAL LAYER ----
SELECT
          PIT_REC_SRC
        , SNAPSHOTDATE
        , PIT_LOAD_DTS
        , SALES_ORGANIZATION_HK
        , SALES_ORGANIZATION_BK
        , LANGUAGE_KEY
        , SALES_ORGANIZATION
        , SALES_ORGANIZATION_NAME
        , CASE  WHEN BKCC = 'Hiding_Tiger' 
                THEN SAT_WINN_PSA_DELETE_IND
          END as IS_DELETED     /* For SAP sources should be use the PSA_DELETE_IND   */    
        , REC_SRC
        , BKCC
FROM JOIN_RESULT