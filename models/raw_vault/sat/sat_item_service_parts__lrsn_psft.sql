---- SRC LAYER ----
WITH
SRC_SITMLR         as ( SELECT * FROM {{ ref('v_psa_stg_item_service_parts__lrsn_psft') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SITMLR         as ( SELECT * FROM STAGING.v_psa_stg_item_service_parts__lrsn_psft )
*/
---- LOGIC LAYER ----

, LOGIC_SITMLR as (
    SELECT
        ITEM_HK
      , PRODUCT_ID
      , SETID
      , L_PART_TYPE
      , L_PART_CLASS
      , L_PART_SUBCOMP
      , BUSINESS_UNIT_SUP
      , L_EXPRESS
      , L_INSTRUCT
      , USER_DIM_1
      , USER_DIM_2
      , USER_DIM_3
      , USER_DIM_4
      , USER_DIM_5
      , USER_DIM_6
      , USER_DIM_7
      , USER_DIM_8
      , USER_DIM_9
      , REVIEW_DATE
      , L_LAST_PROD_DATE
      , L_OBLIGATION_DATE
      , DATETIME_ADDED
      , LASTUPDDTTM
      , LASTUPDOPRID
      , L_DESCRIP_CODE
      , RELEASE_FLAG
      , INV_ITEM_ID
      , L_IMAGE
      , L_RM_CSTM_DISPLAY
      , L_SHOW_DT_BUILT
      , L_PRODUCT_COMMENTS
      , L_CUSTOMER_DESCR
      , L_OUT_OF_STOCK
      , L_CATALOG
      , L_2ND_DAY
      , L_OVERNIGHT
      , L_SHOW_BOM
      , L_PRTS_IMG_LARSON
      , L_PRTS_IMG_PELLA
      , L_ONLINE_SUB_COMP
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
      , PRODUCT_ID
      , SETID
      , L_PART_TYPE
      , L_PART_CLASS
      , L_PART_SUBCOMP
      , BUSINESS_UNIT_SUP
      , L_EXPRESS
      , L_INSTRUCT
      , USER_DIM_1
      , USER_DIM_2
      , USER_DIM_3
      , USER_DIM_4
      , USER_DIM_5
      , USER_DIM_6
      , USER_DIM_7
      , USER_DIM_8
      , USER_DIM_9
      , REVIEW_DATE
      , L_LAST_PROD_DATE
      , L_OBLIGATION_DATE
      , DATETIME_ADDED
      , LASTUPDDTTM
      , LASTUPDOPRID
      , L_DESCRIP_CODE
      , RELEASE_FLAG
      , INV_ITEM_ID
      , L_IMAGE
      , L_RM_CSTM_DISPLAY
      , L_SHOW_DT_BUILT
      , L_PRODUCT_COMMENTS
      , L_CUSTOMER_DESCR
      , L_OUT_OF_STOCK
      , L_CATALOG
      , L_2ND_DAY
      , L_OVERNIGHT
      , L_SHOW_BOM
      , L_PRTS_IMG_LARSON
      , L_PRTS_IMG_PELLA
      , L_ONLINE_SUB_COMP
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
        , PRODUCT_ID
        , SETID
        , L_PART_TYPE
        , L_PART_CLASS
        , L_PART_SUBCOMP
        , BUSINESS_UNIT_SUP
        , L_EXPRESS
        , L_INSTRUCT
        , USER_DIM_1
        , USER_DIM_2
        , USER_DIM_3
        , USER_DIM_4
        , USER_DIM_5
        , USER_DIM_6
        , USER_DIM_7
        , USER_DIM_8
        , USER_DIM_9
        , REVIEW_DATE
        , L_LAST_PROD_DATE
        , L_OBLIGATION_DATE
        , DATETIME_ADDED
        , LASTUPDDTTM
        , LASTUPDOPRID
        , L_DESCRIP_CODE
        , RELEASE_FLAG
        , INV_ITEM_ID
        , L_IMAGE
        , L_RM_CSTM_DISPLAY
        , L_SHOW_DT_BUILT
        , L_PRODUCT_COMMENTS
        , L_CUSTOMER_DESCR
        , L_OUT_OF_STOCK
        , L_CATALOG
        , L_2ND_DAY
        , L_OVERNIGHT
        , L_SHOW_BOM
        , L_PRTS_IMG_LARSON
        , L_PRTS_IMG_PELLA
        , L_ONLINE_SUB_COMP
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
qualify 1= row_number()over(partition by ITEM_HK, SETID,HASHDIFF order by PSA_LOAD_DTS)
union all
    SELECT        MD5_BINARY(GR.VALUE) AS ITEM_HK
      , GR.VALUE as PRODUCT_ID
    , GR.VALUE as SETID
    , null as L_PART_TYPE
    , null as L_PART_CLASS
    , null as L_PART_SUBCOMP
    , null as BUSINESS_UNIT_SUP
    , null as L_EXPRESS
    , null as L_INSTRUCT
    , null as USER_DIM_1
    , null as USER_DIM_2
    , null as USER_DIM_3
    , null as USER_DIM_4
    , null as USER_DIM_5
    , null as USER_DIM_6
    , null as USER_DIM_7
    , null as USER_DIM_8
    , null as USER_DIM_9
    , null as REVIEW_DATE
    , null as L_LAST_PROD_DATE
    , null as L_OBLIGATION_DATE
    , null as DATETIME_ADDED
    , null as LASTUPDDTTM
    , null as LASTUPDOPRID
    , null as L_DESCRIP_CODE
    , null as RELEASE_FLAG
    , null as INV_ITEM_ID
    , null as L_IMAGE
    , null as L_RM_CSTM_DISPLAY
    , null as L_SHOW_DT_BUILT
    , null as L_PRODUCT_COMMENTS
    , null as L_CUSTOMER_DESCR
    , null as L_OUT_OF_STOCK
    , null as L_CATALOG
    , null as L_2ND_DAY
    , null as L_OVERNIGHT
    , null as L_SHOW_BOM
    , null as L_PRTS_IMG_LARSON
    , null as L_PRTS_IMG_PELLA
    , null as L_ONLINE_SUB_COMP
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