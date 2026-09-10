---- SRC LAYER ----
WITH
SRC_HCE            as ( SELECT * FROM {{ ref('hub_cost_element') }} as SRC  ),
SRC_SAT_WINN_COA   as ( SELECT * FROM {{ ref('msat_coa_cost_element__winn_sap') }} as SRC
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY COST_ELEMENT_HK ORDER BY LOAD_DTS DESC)  ),
SRC_SAT_WINN_CCE   as ( SELECT * FROM {{ ref('msat_controlling_cost_element__winn_sap') }} as SRC  
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY COST_ELEMENT_HK ORDER BY LOAD_DTS DESC) )


/*
SRC_HCE            as ( SELECT * FROM RAW_VAULT.hub_cost_element )
, SRC_SAT_WINN_COA   as ( SELECT * FROM RAW_VAULT.msat_coa_cost_element__winn_sap )
, SRC_SAT_WINN_CCE   as ( SELECT * FROM RAW_VAULT.msat_controlling_cost_element__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_HCE as (
    SELECT
        COST_ELEMENT_HK
      , COST_ELEMENT_BK
      , BKCC
      , REC_SRC
    FROM SRC_HCE
)

, LOGIC_SAT_WINN_COA as (
    SELECT
        COST_ELEMENT_HK                                              as                       SAT_WINN_COA_COST_ELEMENT_HK
      , KTOPL                                                        as                                  CHART_OF_ACCOUNTS
      , KSTAR                                                        as                                     COST_ELEMENT_1
      , CAST(ERSDA as INTEGER)                                       as                  SAT_WINN_COA_CREATED_ON__YYYYMMDD
      , USNAM                                                        as                            SAT_WINN_COA_ENTERED_BY
      , KSTSN                                                        as                                     COST_ELEMENT_2
      , PSA_DELETE_IND
    FROM SRC_SAT_WINN_COA
)

, LOGIC_SAT_WINN_CCE as (
    SELECT
        COST_ELEMENT_HK                                              as                       SAT_WINN_CCE_COST_ELEMENT_HK
      , KOKRS                                                        as                                   CONTROLLING_AREA
      , KSTAR                                                        as                                    COST_ELEMENT_11
      , CAST(DATBI as INTEGER)                                       as                            VALID_TO_DATE__YYYYMMDD
      , CAST(DATAB as INTEGER)                                       as                          VALID_FROM_DATE__YYYYMMDD
      , KATYP                                                        as                              COST_ELEMENT_CATEGORY
      , CAST(ERSDA as INTEGER)                                       as                               CREATED_ON__YYYYMMDD
      , USNAM                                                        as                                         ENTERED_BY
    FROM SRC_SAT_WINN_CCE
)
---- RENAME LAYER ----

, RENAME_HCE as (
    SELECT
        COST_ELEMENT_HK
      , COST_ELEMENT_BK
      , BKCC
      , REC_SRC
    FROM LOGIC_HCE
)

, RENAME_SAT_WINN_COA as (
    SELECT
        SAT_WINN_COA_COST_ELEMENT_HK
      , CHART_OF_ACCOUNTS
      , COST_ELEMENT_1
      , SAT_WINN_COA_CREATED_ON__YYYYMMDD
      , SAT_WINN_COA_ENTERED_BY
      , COST_ELEMENT_2
      , PSA_DELETE_IND
    FROM LOGIC_SAT_WINN_COA
)

, RENAME_SAT_WINN_CCE as (
    SELECT
        SAT_WINN_CCE_COST_ELEMENT_HK
      , CONTROLLING_AREA
      , COST_ELEMENT_11
      , VALID_TO_DATE__YYYYMMDD
      , VALID_FROM_DATE__YYYYMMDD
      , COST_ELEMENT_CATEGORY
      , CREATED_ON__YYYYMMDD
      , ENTERED_BY
    FROM LOGIC_SAT_WINN_CCE
)
---- FILTER LAYER ----

, FILTER_HCE as (
    SELECT *
    FROM RENAME_HCE
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
)

, FILTER_SAT_WINN_COA as (
    SELECT *
    FROM RENAME_SAT_WINN_COA
)

, FILTER_SAT_WINN_CCE as (
    SELECT *
    FROM RENAME_SAT_WINN_CCE
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HCE
    LEFT JOIN FILTER_SAT_WINN_COA
        ON FILTER_HCE.COST_ELEMENT_HK = SAT_WINN_COA_COST_ELEMENT_HK
    LEFT JOIN FILTER_SAT_WINN_CCE
        ON FILTER_HCE.COST_ELEMENT_HK = SAT_WINN_CCE_COST_ELEMENT_HK
)

---- FINAL LAYER ----
SELECT
          'PIT_COST_ELEMENT_CURRENT'                                   as PIT_REC_SRC
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PIT_LOAD_DTS
        , COST_ELEMENT_HK
        , COST_ELEMENT_BK
        , SAT_WINN_COA_COST_ELEMENT_HK
        , CHART_OF_ACCOUNTS
        , COST_ELEMENT_1
        , SAT_WINN_COA_CREATED_ON__YYYYMMDD
        , SAT_WINN_COA_ENTERED_BY
        , COST_ELEMENT_2
        , SAT_WINN_CCE_COST_ELEMENT_HK
        , CONTROLLING_AREA
        , COST_ELEMENT_11
        , VALID_TO_DATE__YYYYMMDD
        , VALID_FROM_DATE__YYYYMMDD
        , COST_ELEMENT_CATEGORY
        , CREATED_ON__YYYYMMDD
        , ENTERED_BY
        , BKCC
        , REC_SRC
        , CASE BKCC WHEN 'Hiding_Tiger' THEN PSA_DELETE_IND END as IS_DELETED
FROM JOIN_RESULT
