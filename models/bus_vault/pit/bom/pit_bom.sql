---- SRC LAYER ----
WITH
SRC_H              as ( SELECT * FROM {{ ref('hub_bom') }} as SRC  ),
SRC_BP             as ( SELECT * FROM {{ ref('msat_bom_permanent__winn_sap') }} as SRC 
                         QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY BOM_HK ORDER BY LOAD_DTS DESC) ),
SRC_BH             as ( SELECT * FROM {{ ref('msat_bom_header__winn_sap') }} as SRC 
                         QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY BOM_HK ORDER BY LOAD_DTS DESC) ),
SRC_BS             as ( SELECT * FROM {{ ref('msat_bom_component_selection__winn_sap') }} as SRC 
                         QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY BOM_HK ORDER BY LOAD_DTS DESC) )

/*
SRC_H              as ( SELECT * FROM RAW_VAULT.HUB_BOM )
, SRC_BP             as ( SELECT * FROM RAW_VAULT.MSAT_BOM_PERMANENT__WINN_SAP )
, SRC_BH             as ( SELECT * FROM RAW_VAULT.MSAT_BOM_HEADER__WINN_SAP )
, SRC_BS             as ( SELECT * FROM RAW_VAULT.MSAT_BOM_COMPONENT_SELECTION__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_H as (
    SELECT
        'PIT_BOM'                                                    as                                        PIT_REC_SRC
      , CURRENT_DATE                                                 as                                       SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , BOM_HK
      , BOM_BK
      , REC_SRC
      , BKCC
    FROM SRC_H
)

, LOGIC_BP as (
    SELECT
        BOM_HK                                                       as                                          BP_BOM_HK
      , STLAN                                                        as                                          BOM_Usage
      , ZTEXT                                                        as                                           BOM_Desc
      , STLDT                                                        as                                     PBOM_ChangedOn
    FROM SRC_BP
)

, LOGIC_BH as (
    SELECT
        CASE  WHEN LOEKZ ='X' THEN 'Y'
        WHEN LOEKZ ='' THEN 'N' END                                  as                                  BOM_Deletion_Flag
      , BOM_HK                                                       as                                          BH_BOM_HK
      , MANDT                                                        as                                             Client
      , STLTY                                                        as                                      BOM_Category
      , STLNR                                                        as                                         BOM_Number
      , STLAL                                                        as                                    Alternative_BOM
      , DATUV                                                        as                                     BOM_Valid_From
      , BMENG                                                        as                                            BOM_Qty
      , BMEIN                                                        as                                      BOM_Base_Unit
      , STLST                                                        as                                         BOM_status
      , AENNR                                                        as                                  BOM_Change_Number
      , AEDAT                                                        as                                      BOM_ChangedOn
      , AENAM                                                        as                                         Changed_By
      , LOEKZ
    FROM SRC_BH
)

, LOGIC_BS as (
    SELECT
        BOM_HK                                                       as                                          BS_BOM_HK
      , STLKN                                                        as                               BOM_Item_Node_Number
      , STASZ                                                        as                          BOM_Item_Internal_Counter
      , LKENZ                                                        as                                        BOM_IS_Flag
    FROM SRC_BS
)
---- RENAME LAYER ----

, RENAME_H as (
    SELECT
        PIT_REC_SRC
      , SNAPSHOTDATE
      , PIT_LOAD_DTS
      , BOM_HK
      , BOM_BK
      , REC_SRC
      , BKCC
    FROM LOGIC_H
)

, RENAME_BH as (
    SELECT
        BOM_Deletion_Flag
      , BH_BOM_HK
      , Client
      , BOM_Category 
      , BOM_Number
      , Alternative_BOM
      , BOM_Valid_From
      , BOM_Qty
      , BOM_Base_Unit
      , BOM_status
      , BOM_Change_Number
      , BOM_ChangedOn
      , Changed_By
      , LOEKZ
    FROM LOGIC_BH
)

, RENAME_BS as (
    SELECT
        BS_BOM_HK
      , BOM_Item_Node_Number
      , BOM_Item_Internal_Counter
      , BOM_IS_Flag
    FROM LOGIC_BS
)

, RENAME_BP as (
    SELECT
        BP_BOM_HK
      , BOM_Usage
      , BOM_Desc
      , PBOM_ChangedOn
    FROM LOGIC_BP
)
---- FILTER LAYER ----

, FILTER_H as (
    SELECT *
    FROM RENAME_H
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
)

, FILTER_BP as (
    SELECT *
    FROM RENAME_BP
)

, FILTER_BH as (
    SELECT *
    FROM RENAME_BH
)

, FILTER_BS as (
    SELECT *
    FROM RENAME_BS
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_H
    LEFT JOIN FILTER_BP
        ON FILTER_H.BOM_HK = BP_BOM_HK
    LEFT JOIN FILTER_BH
        ON FILTER_H.BOM_HK = BH_BOM_HK
    LEFT JOIN FILTER_BS
        ON FILTER_H.BOM_HK = BS_BOM_HK
)

---- FINAL LAYER ----
SELECT
          PIT_REC_SRC
        , SNAPSHOTDATE
        , PIT_LOAD_DTS
        , BOM_DELETION_FLAG
        , BOM_HK
        , BOM_BK
        , CLIENT
        , BOM_CATEGORY 
        , BOM_NUMBER
        , ALTERNATIVE_BOM
        , BOM_VALID_FROM
        , BOM_QTY
        , BOM_BASE_UNIT
        , BOM_STATUS
        , BOM_CHANGE_NUMBER
        , BOM_CHANGEDON
        , CHANGED_BY
        , BOM_ITEM_NODE_NUMBER
        , BOM_ITEM_INTERNAL_COUNTER
        , BOM_IS_FLAG
        , BOM_USAGE
        , BOM_DESC
        , PBOM_CHANGEDON
        , REC_SRC
        , BKCC
FROM JOIN_RESULT
