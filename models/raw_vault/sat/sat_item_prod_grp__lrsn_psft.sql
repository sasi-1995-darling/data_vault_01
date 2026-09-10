---- SRC LAYER ----
WITH
SRC_SITMLR         as ( SELECT * FROM {{ ref('v_psa_stg_item_prod_grp__lrsn_psft') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SITMLR         as ( SELECT * FROM STAGING.v_psa_stg_item_prod_grp__lrsn_psft )
*/
---- LOGIC LAYER ----

, LOGIC_SITMLR as (
    SELECT
        ITEM_HK
      , PRODUCT_ID
      , SETID
      , ORDERNO
      , L_COMPANY
      , L_GROUP
      , L_RM_GROUP
      , L_CATEGORY
      , L_CLASS
      , L_SERIES
      , L_MODEL
      , USER_DIM_1
      , USER_DIM_2
      , USER_DIM_3
      , USER_DIM_4
      , USER_DIM_5
      , USER_DIM_6
      , USER_DIM_7
      , USER_DIM_8
      , USER_DIM_9
      , USER_DIM_10
      , USER_DIM_11
      , USER_DIM_12
      , USER_DIM_13
      , USER_DIM_14
      , USER_DIM_15
      , USER_DIM_16
      , USER_DIM_17
      , USER_DIM_18
      , USER_DIM_19
      , USER_DIM_20
      , USER_DIM_21
      , USER_DIM_22
      , USER_DIM_23
      , USER_DIM_24
      , USER_DIM_25
      , PRODUCT_ALIAS
      , L_STYLE
      , L_STYLE2
      , L_SIZEW
      , L_SIZEH
      , L_HARDCOLOR
      , L_DEVIATION
      , L_PICTURE
      , L_HINGING
      , L_LOGO
      , L_FORMAT
      , L_2UP
      , L_MFG_LABEL_CORP
      , L_COVER_UP
      , L_BTO_LOGO
      , L_BTO_FORMAT
      , L_REG_FORMAT
      , L_REG_LOGO
      , L_REG_CPD
      , L_REG_PRODUCT
      , L_INFOCEN
      , PHONE
      , L_QR_LABEL
      , L_QR_CODE
      , PRODUCT_KIT_ID
      , L_PRODUCT_KIT_ID2
      , RELEASE_FLAG
      , DATETIME_ADDED
      , L_LIVE_LABEL
      , L_CERT_LABEL
      , L_WARN_EXCLUDE
      , L_REGISTRIA_LBL
      , L_BACKGROUND
      , L_GRAPHIC1
      , LASTUPDDTTM
      , LAST_MAINT_OPRID
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
      , ORDERNO
      , L_COMPANY
      , L_GROUP
      , L_RM_GROUP
      , L_CATEGORY
      , L_CLASS
      , L_SERIES
      , L_MODEL
      , USER_DIM_1
      , USER_DIM_2
      , USER_DIM_3
      , USER_DIM_4
      , USER_DIM_5
      , USER_DIM_6
      , USER_DIM_7
      , USER_DIM_8
      , USER_DIM_9
      , USER_DIM_10
      , USER_DIM_11
      , USER_DIM_12
      , USER_DIM_13
      , USER_DIM_14
      , USER_DIM_15
      , USER_DIM_16
      , USER_DIM_17
      , USER_DIM_18
      , USER_DIM_19
      , USER_DIM_20
      , USER_DIM_21
      , USER_DIM_22
      , USER_DIM_23
      , USER_DIM_24
      , USER_DIM_25
      , PRODUCT_ALIAS
      , L_STYLE
      , L_STYLE2
      , L_SIZEW
      , L_SIZEH
      , L_HARDCOLOR
      , L_DEVIATION
      , L_PICTURE
      , L_HINGING
      , L_LOGO
      , L_FORMAT
      , L_2UP
      , L_MFG_LABEL_CORP
      , L_COVER_UP
      , L_BTO_LOGO
      , L_BTO_FORMAT
      , L_REG_FORMAT
      , L_REG_LOGO
      , L_REG_CPD
      , L_REG_PRODUCT
      , L_INFOCEN
      , PHONE
      , L_QR_LABEL
      , L_QR_CODE
      , PRODUCT_KIT_ID
      , L_PRODUCT_KIT_ID2
      , RELEASE_FLAG
      , DATETIME_ADDED
      , L_LIVE_LABEL
      , L_CERT_LABEL
      , L_WARN_EXCLUDE
      , L_REGISTRIA_LBL
      , L_BACKGROUND
      , L_GRAPHIC1
      , LASTUPDDTTM
      , LAST_MAINT_OPRID
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
        , ORDERNO
        , L_COMPANY
        , L_GROUP
        , L_RM_GROUP
        , L_CATEGORY
        , L_CLASS
        , L_SERIES
        , L_MODEL
        , USER_DIM_1
        , USER_DIM_2
        , USER_DIM_3
        , USER_DIM_4
        , USER_DIM_5
        , USER_DIM_6
        , USER_DIM_7
        , USER_DIM_8
        , USER_DIM_9
        , USER_DIM_10
        , USER_DIM_11
        , USER_DIM_12
        , USER_DIM_13
        , USER_DIM_14
        , USER_DIM_15
        , USER_DIM_16
        , USER_DIM_17
        , USER_DIM_18
        , USER_DIM_19
        , USER_DIM_20
        , USER_DIM_21
        , USER_DIM_22
        , USER_DIM_23
        , USER_DIM_24
        , USER_DIM_25
        , PRODUCT_ALIAS
        , L_STYLE
        , L_STYLE2
        , L_SIZEW
        , L_SIZEH
        , L_HARDCOLOR
        , L_DEVIATION
        , L_PICTURE
        , L_HINGING
        , L_LOGO
        , L_FORMAT
        , L_2UP
        , L_MFG_LABEL_CORP
        , L_COVER_UP
        , L_BTO_LOGO
        , L_BTO_FORMAT
        , L_REG_FORMAT
        , L_REG_LOGO
        , L_REG_CPD
        , L_REG_PRODUCT
        , L_INFOCEN
        , PHONE
        , L_QR_LABEL
        , L_QR_CODE
        , PRODUCT_KIT_ID
        , L_PRODUCT_KIT_ID2
        , RELEASE_FLAG
        , DATETIME_ADDED
        , L_LIVE_LABEL
        , L_CERT_LABEL
        , L_WARN_EXCLUDE
        , L_REGISTRIA_LBL
        , L_BACKGROUND
        , L_GRAPHIC1
        , LASTUPDDTTM
        , LAST_MAINT_OPRID
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
    , null as ORDERNO
    , null as L_COMPANY
    , null as L_GROUP
    , null as L_RM_GROUP
    , null as L_CATEGORY
    , null as L_CLASS
    , null as L_SERIES
    , null as L_MODEL
    , null as USER_DIM_1
    , null as USER_DIM_2
    , null as USER_DIM_3
    , null as USER_DIM_4
    , null as USER_DIM_5
    , null as USER_DIM_6
    , null as USER_DIM_7
    , null as USER_DIM_8
    , null as USER_DIM_9
    , null as USER_DIM_10
    , null as USER_DIM_11
    , null as USER_DIM_12
    , null as USER_DIM_13
    , null as USER_DIM_14
    , null as USER_DIM_15
    , null as USER_DIM_16
    , null as USER_DIM_17
    , null as USER_DIM_18
    , null as USER_DIM_19
    , null as USER_DIM_20
    , null as USER_DIM_21
    , null as USER_DIM_22
    , null as USER_DIM_23
    , null as USER_DIM_24
    , null as USER_DIM_25
    , null as PRODUCT_ALIAS
    , null as L_STYLE
    , null as L_STYLE2
    , null as L_SIZEW
    , null as L_SIZEH
    , null as L_HARDCOLOR
    , null as L_DEVIATION
    , null as L_PICTURE
    , null as L_HINGING
    , null as L_LOGO
    , null as L_FORMAT
    , null as L_2UP
    , null as L_MFG_LABEL_CORP
    , null as L_COVER_UP
    , null as L_BTO_LOGO
    , null as L_BTO_FORMAT
    , null as L_REG_FORMAT
    , null as L_REG_LOGO
    , null as L_REG_CPD
    , null as L_REG_PRODUCT
    , null as L_INFOCEN
    , null as PHONE
    , null as L_QR_LABEL
    , null as L_QR_CODE
    , null as PRODUCT_KIT_ID
    , null as L_PRODUCT_KIT_ID2
    , null as RELEASE_FLAG
    , null as DATETIME_ADDED
    , null as L_LIVE_LABEL
    , null as L_CERT_LABEL
    , null as L_WARN_EXCLUDE
    , null as L_REGISTRIA_LBL
    , null as L_BACKGROUND
    , null as L_GRAPHIC1
    , null as LASTUPDDTTM
    , null as LAST_MAINT_OPRID
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