---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('lrsn_psft_sysadm', 'ps_l_prod_grp_tbl') }} as SRC 
                        /* The following qualify clause is required to pick the latest change for a day when there are Intra day changes,
                            when Fivetran resync triggered by manual sync multiple times in a day(Resync Happens usually once per week currently). Ex. cust_id ='36196' */
                            qualify 1 = row_number() over(partition by PRODUCT_ID, _fivetran_synced order by psa_load_dts desc) ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM lrsn_psft_sysadm.ps_l_prod_grp_tbl )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        PRODUCT_ID                                                   as                                            ITEM_BK
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
    WHERE rec_src = 'USSDBR.ORCL.PSFTPRD.PS_L_PROD_GRP_TBL'
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
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(SETID::text), '^^') 
            , '||', IFNULL(TRIM(ORDERNO::text), '^^') 
            , '||', IFNULL(TRIM(L_COMPANY::text), '^^') 
            , '||', IFNULL(TRIM(L_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(L_RM_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(L_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(L_CLASS::text), '^^') 
            , '||', IFNULL(TRIM(L_SERIES::text), '^^') 
            , '||', IFNULL(TRIM(L_MODEL::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_1::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_2::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_3::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_4::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_5::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_6::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_7::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_8::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_9::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_10::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_11::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_12::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_13::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_14::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_15::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_16::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_17::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_18::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_19::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_20::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_21::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_22::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_23::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_24::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_25::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_ALIAS::text), '^^') 
            , '||', IFNULL(TRIM(L_STYLE::text), '^^') 
            , '||', IFNULL(TRIM(L_STYLE2::text), '^^') 
            , '||', IFNULL(TRIM(L_SIZEW::text), '^^') 
            , '||', IFNULL(TRIM(L_SIZEH::text), '^^') 
            , '||', IFNULL(TRIM(L_HARDCOLOR::text), '^^') 
            , '||', IFNULL(TRIM(L_DEVIATION::text), '^^') 
            , '||', IFNULL(TRIM(L_PICTURE::text), '^^') 
            , '||', IFNULL(TRIM(L_HINGING::text), '^^') 
            , '||', IFNULL(TRIM(L_LOGO::text), '^^') 
            , '||', IFNULL(TRIM(L_FORMAT::text), '^^') 
            , '||', IFNULL(TRIM(L_2UP::text), '^^') 
            , '||', IFNULL(TRIM(L_MFG_LABEL_CORP::text), '^^') 
            , '||', IFNULL(TRIM(L_COVER_UP::text), '^^') 
            , '||', IFNULL(TRIM(L_BTO_LOGO::text), '^^') 
            , '||', IFNULL(TRIM(L_BTO_FORMAT::text), '^^') 
            , '||', IFNULL(TRIM(L_REG_FORMAT::text), '^^') 
            , '||', IFNULL(TRIM(L_REG_LOGO::text), '^^') 
            , '||', IFNULL(TRIM(L_REG_CPD::text), '^^') 
            , '||', IFNULL(TRIM(L_REG_PRODUCT::text), '^^') 
            , '||', IFNULL(TRIM(L_INFOCEN::text), '^^') 
            , '||', IFNULL(TRIM(PHONE::text), '^^') 
            , '||', IFNULL(TRIM(L_QR_LABEL::text), '^^') 
            , '||', IFNULL(TRIM(L_QR_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_KIT_ID::text), '^^') 
            , '||', IFNULL(TRIM(L_PRODUCT_KIT_ID2::text), '^^') 
            , '||', IFNULL(TRIM(RELEASE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(DATETIME_ADDED::text), '^^') 
            , '||', IFNULL(TRIM(L_LIVE_LABEL::text), '^^') 
            , '||', IFNULL(TRIM(L_CERT_LABEL::text), '^^') 
            , '||', IFNULL(TRIM(L_WARN_EXCLUDE::text), '^^') 
            , '||', IFNULL(TRIM(L_REGISTRIA_LBL::text), '^^') 
            , '||', IFNULL(TRIM(L_BACKGROUND::text), '^^') 
            , '||', IFNULL(TRIM(L_GRAPHIC1::text), '^^') 
            , '||', IFNULL(TRIM(LASTUPDDTTM::text), '^^') 
            , '||', IFNULL(TRIM(LAST_MAINT_OPRID::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
