---- SRC LAYER ----
WITH
SRC_SITMLR         as ( SELECT * FROM {{ ref('v_psa_stg_item_master__lrsn_psft') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SITMLR         as ( SELECT * FROM STAGING.v_psa_stg_item_master__lrsn_psft )
*/
---- LOGIC LAYER ----

, LOGIC_SITMLR as (
    SELECT
        ITEM_HK
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
      , HASHDIFF
    FROM SRC_SITMLR
)
---- RENAME LAYER ----

, RENAME_SITMLR as (
    SELECT
        ITEM_HK
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
      , HASHDIFF
    FROM LOGIC_SITMLR
)
---- FILTER LAYER ----

, FILTER_SITMLR as (
    SELECT *
    FROM RENAME_SITMLR
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SITMLR
)

---- FINAL LAYER ----
SELECT
          ITEM_HK
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
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ITEM_HK= JOIN_RESULT.ITEM_HK
   AND existing.SETID = JOIN_RESULT.SETID
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by ITEM_HK,SETID, HASHDIFF order by PSA_LOAD_DTS)
union all
    SELECT        MD5_BINARY(GR.VALUE) AS ITEM_HK
    , GR.VALUE as INV_ITEM_ID
    , GR.VALUE as SETID
    , null as ITM_STATUS_EFFDT
    , null as ITM_STATUS_CURRENT
    , null as ITM_STAT_DT_FUTURE
    , null as ITM_STATUS_FUTURE
    , null as DESCR
    , null as DESCR60
    , null as DESCRSHORT
    , null as UNIT_MEASURE_STD
    , null as INV_ITEM_GROUP
    , null as INV_PROD_FAM_CD
    , null as CATEGORY_ID
    , null as DATE_ADDED
    , null as ORIG_OPRID
    , null as APPROVAL_OPRID
    , null as APPROVAL_DATE
    , null as LAST_MAINT_OPRID
    , null as LAST_DTTM_UPDATE
    , null as CHANGE_FIELD
    , null as INVENTORY_ITEM
    , null as LOT_CONTROL
    , null as SERIAL_CONTROL
    , null as SHIP_SERIAL_CNTRL
    , null as NON_OWN_FLAG
    , null as APPROV_REQUIRED
    , null as APPROV_SUBMITTED
    , null as DENIAL_REASON
    , null as STAGED_DATE_FLAG
    , null as DIST_CFG_FLAG
    , null as PRDN_CFG_FLAG
    , null as CFG_CODE_OPT
    , null as CFG_COST_OPT
    , null as CFG_LOT_OPT
    , null as CP_TEMPLATE_ID
    , null as CP_TREE_DIST
    , null as CP_TREE_PRDN
    , null as CM_GROUP
    , null as MATERIAL_RECON_FLG
    , null as USG_TRCKNG_METHOD
    , null as CONSIGNED_FLAG
    , null as PL_PRIO_FAMILY
    , null as ITEM_FIELD_C30_A
    , null as ITEM_FIELD_C30_B
    , null as ITEM_FIELD_C30_C
    , null as ITEM_FIELD_C30_D
    , null as ITEM_FIELD_C1_A
    , null as ITEM_FIELD_C1_B
    , null as ITEM_FIELD_C1_C
    , null as ITEM_FIELD_C1_D
    , null as ITEM_FIELD_C10_A
    , null as ITEM_FIELD_C10_B
    , null as ITEM_FIELD_C10_C
    , null as ITEM_FIELD_C10_D
    , null as ITEM_FIELD_C2
    , null as ITEM_FIELD_C4
    , null as ITEM_FIELD_C6
    , null as ITEM_FIELD_C8
    , null as ITEM_FIELD_N12_A
    , null as ITEM_FIELD_N12_B
    , null as ITEM_FIELD_N12_C
    , null as ITEM_FIELD_N12_D
    , null as ITEM_FIELD_N15_A
    , null as ITEM_FIELD_N15_B
    , null as ITEM_FIELD_N15_C
    , null as ITEM_FIELD_N15_D
    , null as PROMISE_OPTION
    , null as DEVICE_TRACKING
    , null as SERIAL_IN_PRDN
    , null as TRACE_USAGE
    , null as TRACE_CHANGE
    , null as PHYSICAL_NATURE    
, null as _FIVETRAN_DELETED
, null as _FIVETRAN_ID
, null as _FIVETRAN_SYNCED
, null as PSA_DELETE_IND
, null as PSA_LOAD_DTS
, null as PSA_RECORD_SOURCE
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)::TIMESTAMP as LOAD_DTS
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, ''::BINARY as HASHDIFF
  FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}