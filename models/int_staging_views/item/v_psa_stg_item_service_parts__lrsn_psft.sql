---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('lrsn_psft_sysadm', 'ps_l_sp_prod') }} as SRC 
                        /* The following qualify clause is required to pick the latest change for a day when there are Intra day changes,
                            when Fivetran resync triggered by manual sync multiple times in a day(Resync Happens usually once per week currently). Ex. cust_id ='36196' */
                            qualify 1 = row_number() over(partition by PRODUCT_ID, _fivetran_synced order by psa_load_dts desc) ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM lrsn_psft_sysadm.ps_l_sp_prod )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        PRODUCT_ID                                                   as                                            ITEM_BK
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
    WHERE rec_src = 'USSDBR.ORCL.PSFTPRD.PS_L_SP_PROD'
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
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(SETID::text), '^^') 
            , '||', IFNULL(TRIM(L_PART_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(L_PART_CLASS::text), '^^') 
            , '||', IFNULL(TRIM(L_PART_SUBCOMP::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_UNIT_SUP::text), '^^') 
            , '||', IFNULL(TRIM(L_EXPRESS::text), '^^') 
            , '||', IFNULL(TRIM(L_INSTRUCT::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_1::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_2::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_3::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_4::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_5::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_6::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_7::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_8::text), '^^') 
            , '||', IFNULL(TRIM(USER_DIM_9::text), '^^') 
            , '||', IFNULL(TRIM(REVIEW_DATE::text), '^^') 
            , '||', IFNULL(TRIM(L_LAST_PROD_DATE::text), '^^') 
            , '||', IFNULL(TRIM(L_OBLIGATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(DATETIME_ADDED::text), '^^') 
            , '||', IFNULL(TRIM(LASTUPDDTTM::text), '^^') 
            , '||', IFNULL(TRIM(LASTUPDOPRID::text), '^^') 
            , '||', IFNULL(TRIM(L_DESCRIP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(RELEASE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(INV_ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(L_IMAGE::text), '^^') 
            , '||', IFNULL(TRIM(L_RM_CSTM_DISPLAY::text), '^^') 
            , '||', IFNULL(TRIM(L_SHOW_DT_BUILT::text), '^^') 
            , '||', IFNULL(TRIM(L_PRODUCT_COMMENTS::text), '^^') 
            , '||', IFNULL(TRIM(L_CUSTOMER_DESCR::text), '^^') 
            , '||', IFNULL(TRIM(L_OUT_OF_STOCK::text), '^^') 
            , '||', IFNULL(TRIM(L_CATALOG::text), '^^') 
            , '||', IFNULL(TRIM(L_2ND_DAY::text), '^^') 
            , '||', IFNULL(TRIM(L_OVERNIGHT::text), '^^') 
            , '||', IFNULL(TRIM(L_SHOW_BOM::text), '^^') 
            , '||', IFNULL(TRIM(L_PRTS_IMG_LARSON::text), '^^') 
            , '||', IFNULL(TRIM(L_PRTS_IMG_PELLA::text), '^^') 
            , '||', IFNULL(TRIM(L_ONLINE_SUB_COMP::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
