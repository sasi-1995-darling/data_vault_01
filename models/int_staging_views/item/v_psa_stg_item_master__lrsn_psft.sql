---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('lrsn_psft_sysadm', 'ps_master_item_tbl') }} as SRC 
                        /* The following qualify clause is required to pick the latest change for a day when there are Intra day changes,
                            when Fivetran resync triggered by manual sync multiple times in a day(Resync Happens usually once per week currently). Ex. cust_id ='36196' */
                            where TRIM(inv_item_id) <> ''   --added where clause to filter out data quality issue from source 2026-01-07
                            qualify 1 = row_number() over(partition by INV_ITEM_ID,SETID, _fivetran_synced order by psa_load_dts desc) ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM lrsn_psft_sysadm.ps_master_item_tbl )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        INV_ITEM_ID                                               as                                            ITEM_BK
      , INV_ITEM_ID
      , SETID
      , ITM_STATUS_EFFDT
      , ITM_STATUS_CURRENT
      , ITM_STAT_DT_FUTURE
      , ITM_STATUS_FUTURE
      , DESCR
      , DESCR60
      , DESCRSHORT
      , UNIT_MEASURE_STD
      , INV_ITEM_GROUP
      , INV_PROD_FAM_CD
      , CATEGORY_ID
      , DATE_ADDED
      , ORIG_OPRID
      , APPROVAL_OPRID
      , APPROVAL_DATE
      , LAST_MAINT_OPRID
      , LAST_DTTM_UPDATE
      , CHANGE_FIELD
      , INVENTORY_ITEM
      , LOT_CONTROL
      , SERIAL_CONTROL
      , SHIP_SERIAL_CNTRL
      , NON_OWN_FLAG
      , APPROV_REQUIRED
      , APPROV_SUBMITTED
      , DENIAL_REASON
      , STAGED_DATE_FLAG
      , DIST_CFG_FLAG
      , PRDN_CFG_FLAG
      , CFG_CODE_OPT
      , CFG_COST_OPT
      , CFG_LOT_OPT
      , CP_TEMPLATE_ID
      , CP_TREE_DIST
      , CP_TREE_PRDN
      , CM_GROUP
      , MATERIAL_RECON_FLG
      , USG_TRCKNG_METHOD
      , CONSIGNED_FLAG
      , PL_PRIO_FAMILY
      , ITEM_FIELD_C30_A
      , ITEM_FIELD_C30_B
      , ITEM_FIELD_C30_C
      , ITEM_FIELD_C30_D
      , ITEM_FIELD_C1_A
      , ITEM_FIELD_C1_B
      , ITEM_FIELD_C1_C
      , ITEM_FIELD_C1_D
      , ITEM_FIELD_C10_A
      , ITEM_FIELD_C10_B
      , ITEM_FIELD_C10_C
      , ITEM_FIELD_C10_D
      , ITEM_FIELD_C2
      , ITEM_FIELD_C4
      , ITEM_FIELD_C6
      , ITEM_FIELD_C8
      , ITEM_FIELD_N12_A
      , ITEM_FIELD_N12_B
      , ITEM_FIELD_N12_C
      , ITEM_FIELD_N12_D
      , ITEM_FIELD_N15_A
      , ITEM_FIELD_N15_B
      , ITEM_FIELD_N15_C
      , ITEM_FIELD_N15_D
      , PROMISE_OPTION
      , DEVICE_TRACKING
      , SERIAL_IN_PRDN
      , TRACE_USAGE
      , TRACE_CHANGE
      , PHYSICAL_NATURE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED )                   as                                           LOAD_DTS
    FROM SRC_S
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        ITEM_BK
      , INV_ITEM_ID
      , SETID
      , ITM_STATUS_EFFDT
      , ITM_STATUS_CURRENT
      , ITM_STAT_DT_FUTURE
      , ITM_STATUS_FUTURE
      , DESCR
      , DESCR60
      , DESCRSHORT
      , UNIT_MEASURE_STD
      , INV_ITEM_GROUP
      , INV_PROD_FAM_CD
      , CATEGORY_ID
      , DATE_ADDED
      , ORIG_OPRID
      , APPROVAL_OPRID
      , APPROVAL_DATE
      , LAST_MAINT_OPRID
      , LAST_DTTM_UPDATE
      , CHANGE_FIELD
      , INVENTORY_ITEM
      , LOT_CONTROL
      , SERIAL_CONTROL
      , SHIP_SERIAL_CNTRL
      , NON_OWN_FLAG
      , APPROV_REQUIRED
      , APPROV_SUBMITTED
      , DENIAL_REASON
      , STAGED_DATE_FLAG
      , DIST_CFG_FLAG
      , PRDN_CFG_FLAG
      , CFG_CODE_OPT
      , CFG_COST_OPT
      , CFG_LOT_OPT
      , CP_TEMPLATE_ID
      , CP_TREE_DIST
      , CP_TREE_PRDN
      , CM_GROUP
      , MATERIAL_RECON_FLG
      , USG_TRCKNG_METHOD
      , CONSIGNED_FLAG
      , PL_PRIO_FAMILY
      , ITEM_FIELD_C30_A
      , ITEM_FIELD_C30_B
      , ITEM_FIELD_C30_C
      , ITEM_FIELD_C30_D
      , ITEM_FIELD_C1_A
      , ITEM_FIELD_C1_B
      , ITEM_FIELD_C1_C
      , ITEM_FIELD_C1_D
      , ITEM_FIELD_C10_A
      , ITEM_FIELD_C10_B
      , ITEM_FIELD_C10_C
      , ITEM_FIELD_C10_D
      , ITEM_FIELD_C2
      , ITEM_FIELD_C4
      , ITEM_FIELD_C6
      , ITEM_FIELD_C8
      , ITEM_FIELD_N12_A
      , ITEM_FIELD_N12_B
      , ITEM_FIELD_N12_C
      , ITEM_FIELD_N12_D
      , ITEM_FIELD_N15_A
      , ITEM_FIELD_N15_B
      , ITEM_FIELD_N15_C
      , ITEM_FIELD_N15_D
      , PROMISE_OPTION
      , DEVICE_TRACKING
      , SERIAL_IN_PRDN
      , TRACE_USAGE
      , TRACE_CHANGE
      , PHYSICAL_NATURE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
    FROM LOGIC_S
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USSDBR.ORCL.PSFTPRD.PS_MASTER_ITEM_TBL'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          ITEM_BK
        , INV_ITEM_ID
        , SETID
        , ITM_STATUS_EFFDT
        , ITM_STATUS_CURRENT
        , ITM_STAT_DT_FUTURE
        , ITM_STATUS_FUTURE
        , DESCR
        , DESCR60
        , DESCRSHORT
        , UNIT_MEASURE_STD
        , INV_ITEM_GROUP
        , INV_PROD_FAM_CD
        , CATEGORY_ID
        , DATE_ADDED
        , ORIG_OPRID
        , APPROVAL_OPRID
        , APPROVAL_DATE
        , LAST_MAINT_OPRID
        , LAST_DTTM_UPDATE
        , CHANGE_FIELD
        , INVENTORY_ITEM
        , LOT_CONTROL
        , SERIAL_CONTROL
        , SHIP_SERIAL_CNTRL
        , NON_OWN_FLAG
        , APPROV_REQUIRED
        , APPROV_SUBMITTED
        , DENIAL_REASON
        , STAGED_DATE_FLAG
        , DIST_CFG_FLAG
        , PRDN_CFG_FLAG
        , CFG_CODE_OPT
        , CFG_COST_OPT
        , CFG_LOT_OPT
        , CP_TEMPLATE_ID
        , CP_TREE_DIST
        , CP_TREE_PRDN
        , CM_GROUP
        , MATERIAL_RECON_FLG
        , USG_TRCKNG_METHOD
        , CONSIGNED_FLAG
        , PL_PRIO_FAMILY
        , ITEM_FIELD_C30_A
        , ITEM_FIELD_C30_B
        , ITEM_FIELD_C30_C
        , ITEM_FIELD_C30_D
        , ITEM_FIELD_C1_A
        , ITEM_FIELD_C1_B
        , ITEM_FIELD_C1_C
        , ITEM_FIELD_C1_D
        , ITEM_FIELD_C10_A
        , ITEM_FIELD_C10_B
        , ITEM_FIELD_C10_C
        , ITEM_FIELD_C10_D
        , ITEM_FIELD_C2
        , ITEM_FIELD_C4
        , ITEM_FIELD_C6
        , ITEM_FIELD_C8
        , ITEM_FIELD_N12_A
        , ITEM_FIELD_N12_B
        , ITEM_FIELD_N12_C
        , ITEM_FIELD_N12_D
        , ITEM_FIELD_N15_A
        , ITEM_FIELD_N15_B
        , ITEM_FIELD_N15_C
        , ITEM_FIELD_N15_D
        , PROMISE_OPTION
        , DEVICE_TRACKING
        , SERIAL_IN_PRDN
        , TRACE_USAGE
        , TRACE_CHANGE
        , PHYSICAL_NATURE
        , _FIVETRAN_DELETED
        , _FIVETRAN_ID
        , _FIVETRAN_SYNCED
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , BKCC
        ,  '-2'                                                        as PLANT_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_ITEM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(SETID::text), '^^') 
            , '||', IFNULL(TRIM(ITM_STATUS_EFFDT::text), '^^') 
            , '||', IFNULL(TRIM(ITM_STATUS_CURRENT::text), '^^') 
            , '||', IFNULL(TRIM(ITM_STAT_DT_FUTURE::text), '^^') 
            , '||', IFNULL(TRIM(ITM_STATUS_FUTURE::text), '^^') 
            , '||', IFNULL(TRIM(DESCR::text), '^^') 
            , '||', IFNULL(TRIM(DESCR60::text), '^^') 
            , '||', IFNULL(TRIM(DESCRSHORT::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_MEASURE_STD::text), '^^') 
            , '||', IFNULL(TRIM(INV_ITEM_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(INV_PROD_FAM_CD::text), '^^') 
            , '||', IFNULL(TRIM(CATEGORY_ID::text), '^^') 
            , '||', IFNULL(TRIM(DATE_ADDED::text), '^^') 
            , '||', IFNULL(TRIM(ORIG_OPRID::text), '^^') 
            , '||', IFNULL(TRIM(APPROVAL_OPRID::text), '^^') 
            , '||', IFNULL(TRIM(APPROVAL_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_MAINT_OPRID::text), '^^') 
            , '||', IFNULL(TRIM(LAST_DTTM_UPDATE::text), '^^') 
            , '||', IFNULL(TRIM(CHANGE_FIELD::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_ITEM::text), '^^') 
            , '||', IFNULL(TRIM(LOT_CONTROL::text), '^^') 
            , '||', IFNULL(TRIM(SERIAL_CONTROL::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_SERIAL_CNTRL::text), '^^') 
            , '||', IFNULL(TRIM(NON_OWN_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(APPROV_REQUIRED::text), '^^') 
            , '||', IFNULL(TRIM(APPROV_SUBMITTED::text), '^^') 
            , '||', IFNULL(TRIM(DENIAL_REASON::text), '^^') 
            , '||', IFNULL(TRIM(STAGED_DATE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(DIST_CFG_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PRDN_CFG_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CFG_CODE_OPT::text), '^^') 
            , '||', IFNULL(TRIM(CFG_COST_OPT::text), '^^') 
            , '||', IFNULL(TRIM(CFG_LOT_OPT::text), '^^') 
            , '||', IFNULL(TRIM(CP_TEMPLATE_ID::text), '^^') 
            , '||', IFNULL(TRIM(CP_TREE_DIST::text), '^^') 
            , '||', IFNULL(TRIM(CP_TREE_PRDN::text), '^^') 
            , '||', IFNULL(TRIM(CM_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(MATERIAL_RECON_FLG::text), '^^') 
            , '||', IFNULL(TRIM(USG_TRCKNG_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(CONSIGNED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PL_PRIO_FAMILY::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C30_A::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C30_B::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C30_C::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C30_D::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C1_A::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C1_B::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C1_C::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C1_D::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C10_A::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C10_B::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C10_C::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C10_D::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C2::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C4::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C6::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_C8::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_N12_A::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_N12_B::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_N12_C::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_N12_D::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_N15_A::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_N15_B::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_N15_C::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FIELD_N15_D::text), '^^') 
            , '||', IFNULL(TRIM(PROMISE_OPTION::text), '^^') 
            , '||', IFNULL(TRIM(DEVICE_TRACKING::text), '^^') 
            , '||', IFNULL(TRIM(SERIAL_IN_PRDN::text), '^^') 
            , '||', IFNULL(TRIM(TRACE_USAGE::text), '^^') 
            , '||', IFNULL(TRIM(TRACE_CHANGE::text), '^^') 
            , '||', IFNULL(TRIM(PHYSICAL_NATURE::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
