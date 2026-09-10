---- SRC LAYER ----
WITH
SRC_HT             as ( SELECT BKCC, REC_SRC, TASKLIST_GROUP_BK, TASKLIST_GROUP_HK FROM {{ ref('hub_tasklist_group') }} as SRC  ),
SRC_MT             as ( SELECT ARBID, DATUV, KTEXT, LOEKZ, LOSBS, LOSVN, PLNAL, STATU, PSA_DELETE_IND, TASKLIST_GROUP_HK, VERWE FROM {{ ref('msat_tasklist_group__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by TASKLIST_GROUP_HK order by LOAD_DTS DESC) )

/*
SRC_HT             as ( SELECT * FROM RAW_VAULT.HUB_TASKLIST_GROUP )
SRC_MT             as ( SELECT * FROM RAW_VAULT.MSAT_TASKLIST_GROUP__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_HT as (
    SELECT
        CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , BKCC
      , 'PIT_TASKLIST_GROUP'                                         as                                        PIT_REC_SRC
      , REC_SRC
      , TASKLIST_GROUP_BK
      , TASKLIST_GROUP_HK
    FROM SRC_HT
)

, LOGIC_MT as (
    SELECT
        TASKLIST_GROUP_HK                                            as                               MT_TASKLIST_GROUP_HK
      , DATUV                                                        as                                    VALID_FROM_DATE
      , VERWE                                                        as                                     TASKLIST_USAGE
      , KTEXT                                                        as                                   TASK_DESCRIPTION
      , ARBID                                                        as                                   WC_WITH_PLANNING
      , STATU                                                        as                                    TASKLIST_STATUS
      , LOEKZ                                                        as                                 DELETION_INDICATOR
      , PLNAL                                                        as                                      GROUP_COUNTER
      , LOSVN                                                        as                                      LOT_SIZE_FROM
      , LOSBS                                                        as                                        LOT_SIZE_TO
      , PSA_DELETE_IND                                               as                            SAT_WINN_PSA_DELETE_IND
    FROM SRC_MT
)
---- RENAME LAYER ----

, RENAME_HT as (
    SELECT
        PIT_LOAD_DTS
      , BKCC
      , PIT_REC_SRC
      , REC_SRC
      , TASKLIST_GROUP_BK
      , TASKLIST_GROUP_HK
    FROM LOGIC_HT
)

, RENAME_MT as (
    SELECT
        MT_TASKLIST_GROUP_HK
      , VALID_FROM_DATE
      , TASKLIST_USAGE
      , TASK_DESCRIPTION
      , WC_WITH_PLANNING
      , TASKLIST_STATUS
      , DELETION_INDICATOR
      , GROUP_COUNTER
      , LOT_SIZE_FROM
      , LOT_SIZE_TO
      , SAT_WINN_PSA_DELETE_IND
    FROM LOGIC_MT
)
---- FILTER LAYER ----

, FILTER_HT as (
    SELECT *
    FROM RENAME_HT
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'
)

, FILTER_MT as (
    SELECT *
    FROM RENAME_MT
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HT
    INNER JOIN FILTER_MT
        ON FILTER_HT.TASKLIST_GROUP_HK = FILTER_MT.MT_TASKLIST_GROUP_HK
)

---- FINAL LAYER ----
SELECT
          row_number() over(order by 1)                                as SEQ_ID
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , PIT_LOAD_DTS
        , BKCC
        , PIT_REC_SRC
        , REC_SRC
        , TASKLIST_GROUP_BK
        , TASKLIST_GROUP_HK
        , VALID_FROM_DATE::INTEGER                             as                     VALID_FROM_DATE__YYYYMMDD
        , TASKLIST_USAGE
        , TASK_DESCRIPTION
        , WC_WITH_PLANNING
        , TASKLIST_STATUS
        , DELETION_INDICATOR
        , GROUP_COUNTER
        , LOT_SIZE_FROM
        , LOT_SIZE_TO
        , CASE  WHEN BKCC = 'Hiding_Tiger' THEN SAT_WINN_PSA_DELETE_IND
           END as IS_DELETED
FROM JOIN_RESULT
