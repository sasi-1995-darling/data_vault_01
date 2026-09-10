---- SRC LAYER ----
WITH
SRC_H              as ( SELECT BKCC, REC_SRC, COST_TRANSACTION_TYPE_BK, COST_TRANSACTION_TYPE_HK FROM {{ ref('hub_cost_transaction_type') }} as SRC  ),
SRC_SAT_WINN       as ( SELECT ACTGRP, ANWST, NVVRG, PERSP, PRVRG, PSIKZ, SUBGRP, COST_TRANSACTION_TYPE_HK, VRGCO, VRGJV, VRGNG, VRGSV, WTKAT, XCOEJ, XCOEJL, XCOEJR, XCOEJT, XCOEP, XCOEPB, XCOEPL, XCOEPR, XCOEPT, XCOFP, XCOOI, XCOSP, XCOSS, XFMGM, PSA_DELETE_IND FROM {{ ref('sat_cost_transaction_type__winn_sap') }} as SRC 
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY COST_TRANSACTION_TYPE_HK ORDER BY LOAD_DTS DESC) )

/*
SRC_H              as ( SELECT * FROM RAW_VAULT.HUB_TRANSACTION_TYPE )
SRC_SAT_WINN       as ( SELECT * FROM RAW_VAULT.SAT_COST_TRANSACTION_TYPE__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_H as (
    SELECT
        'PIT_TRANSACTION_TYPE'                                       as                                        PIT_REC_SRC
      , CURRENT_DATE                                                 as                                       SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , COST_TRANSACTION_TYPE_HK
      , COST_TRANSACTION_TYPE_BK
      , BKCC
      , REC_SRC
    FROM SRC_H
)

, LOGIC_SAT_WINN as (
    SELECT
        COST_TRANSACTION_TYPE_HK                                          as                       SAT_WINN_TRANSACTION_TYPE_HK
      , VRGNG                                                        as                                   COST_TRANSACTION_TYPE
      , VRGSV                                                        as                 INDICATOR_STATUS_ADMIN_TRANSACTION
      , ANWST                                                        as                  FLAG_PROCEDURE_CHANGE_USER_STATUS
      , PRVRG                                                        as                           STATUS_CHECK_TRANSACTION
      , VRGJV                                                        as                           PROCEDURE_JOINT_VENTURES
      , VRGCO                                                        as                FLAG_PROCEDURE_ASSIGN_CO_DOC_NUMBER
      , NVVRG                                                        as           TRANSACTION_FOR_CO_DOC_NUMBER_ASSIGNMENT
      , PERSP                                                        as                     IND_TRANSACTION_CO_PERIOD_LOCK
      , PSIKZ                                                        as                                     CLASSIFICATION
      , WTKAT                                                        as                                     VALUE_CATEGORY
      , ACTGRP                                                       as                                     ACTIVITY_GROUP
      , SUBGRP                                                       as                                 CO_ACTION_SUBGROUP
      , XCOEP                                                        as                               IND_TRANSACTION_COEP
      , XCOEJ                                                        as                               IND_TRANSACTION_COEJ
      , XCOOI                                                        as                               IND_TRANSACTION_COOI
      , XCOSP                                                        as                               IND_TRANSACTION_COSP
      , XCOSS                                                        as                               IND_TRANSACTION_COSS
      , XCOEPL                                                       as                              IND_TRANSACTION_COEPL
      , XCOEJL                                                       as                              IND_TRANSACTION_COEJL
      , XCOEPR                                                       as                              IND_TRANSACTION_COEPR
      , XCOEJR                                                       as                              IND_TRANSACTION_COEJR
      , XCOEPT                                                       as                              IND_TRANSACTION_COEPT
      , XCOEJT                                                       as                              IND_TRANSACTION_COEJT
      , XCOEPB                                                       as                              IND_TRANSACTION_COEPB
      , XCOFP                                                        as                               IND_TRANSACTION_COFP
      , XFMGM                                                        as                      IND_ACTIVITY_FUNDS_MANAGEMENT
      , PSA_DELETE_IND
    FROM SRC_SAT_WINN
)
---- RENAME LAYER ----

, RENAME_H as (
    SELECT
        PIT_REC_SRC
      , SNAPSHOTDATE
      , PIT_LOAD_DTS
      , COST_TRANSACTION_TYPE_HK
      , COST_TRANSACTION_TYPE_BK
      , BKCC
      , REC_SRC
    FROM LOGIC_H
)

, RENAME_SAT_WINN as (
    SELECT
        SAT_WINN_TRANSACTION_TYPE_HK
      , COST_TRANSACTION_TYPE
      , INDICATOR_STATUS_ADMIN_TRANSACTION
      , FLAG_PROCEDURE_CHANGE_USER_STATUS
      , STATUS_CHECK_TRANSACTION
      , PROCEDURE_JOINT_VENTURES
      , FLAG_PROCEDURE_ASSIGN_CO_DOC_NUMBER
      , TRANSACTION_FOR_CO_DOC_NUMBER_ASSIGNMENT
      , IND_TRANSACTION_CO_PERIOD_LOCK
      , CLASSIFICATION
      , VALUE_CATEGORY
      , ACTIVITY_GROUP
      , CO_ACTION_SUBGROUP
      , IND_TRANSACTION_COEP
      , IND_TRANSACTION_COEJ
      , IND_TRANSACTION_COOI
      , IND_TRANSACTION_COSP
      , IND_TRANSACTION_COSS
      , IND_TRANSACTION_COEPL
      , IND_TRANSACTION_COEJL
      , IND_TRANSACTION_COEPR
      , IND_TRANSACTION_COEJR
      , IND_TRANSACTION_COEPT
      , IND_TRANSACTION_COEJT
      , IND_TRANSACTION_COEPB
      , IND_TRANSACTION_COFP
      , IND_ACTIVITY_FUNDS_MANAGEMENT
      , PSA_DELETE_IND
    FROM LOGIC_SAT_WINN
)
---- FILTER LAYER ----

, FILTER_H as (
    SELECT *
    FROM RENAME_H
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
)

, FILTER_SAT_WINN as (
    SELECT *
    FROM RENAME_SAT_WINN
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_H
    LEFT JOIN FILTER_SAT_WINN
        ON FILTER_H.COST_TRANSACTION_TYPE_HK = FILTER_SAT_WINN.SAT_WINN_TRANSACTION_TYPE_HK
)

---- FINAL LAYER ----
SELECT
          PIT_REC_SRC
        , SNAPSHOTDATE
        , PIT_LOAD_DTS
        , COST_TRANSACTION_TYPE_HK
        , COST_TRANSACTION_TYPE_BK
        , COST_TRANSACTION_TYPE
        , INDICATOR_STATUS_ADMIN_TRANSACTION
        , FLAG_PROCEDURE_CHANGE_USER_STATUS
        , STATUS_CHECK_TRANSACTION
        , PROCEDURE_JOINT_VENTURES
        , FLAG_PROCEDURE_ASSIGN_CO_DOC_NUMBER
        , TRANSACTION_FOR_CO_DOC_NUMBER_ASSIGNMENT
        , IND_TRANSACTION_CO_PERIOD_LOCK
        , CLASSIFICATION
        , VALUE_CATEGORY
        , ACTIVITY_GROUP
        , CO_ACTION_SUBGROUP
        , IND_TRANSACTION_COEP
        , IND_TRANSACTION_COEJ
        , IND_TRANSACTION_COOI
        , IND_TRANSACTION_COSP
        , IND_TRANSACTION_COSS
        , IND_TRANSACTION_COEPL
        , IND_TRANSACTION_COEJL
        , IND_TRANSACTION_COEPR
        , IND_TRANSACTION_COEJR
        , IND_TRANSACTION_COEPT
        , IND_TRANSACTION_COEJT
        , IND_TRANSACTION_COEPB
        , IND_TRANSACTION_COFP
        , IND_ACTIVITY_FUNDS_MANAGEMENT
        , BKCC
        , REC_SRC
        , CASE BKCC WHEN 'Hiding_Tiger' THEN PSA_DELETE_IND END as IS_DELETED
FROM JOIN_RESULT