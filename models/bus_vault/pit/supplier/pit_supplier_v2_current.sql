---- SRC LAYER ----
WITH
SRC_H              as ( 
    SELECT 
        SUPPLIER_HK, 
        SUPPLIER_BK, 
        REC_SRC, 
        BKCC 
    FROM {{ ref('hub_supplier_v2') }} 
),
SRC_SAT_WINN       as ( 
    SELECT 
        SUPPLIER_HK, 
        NAME1, 
        KTOKK, 
        LIFNR, 
        NAME2, 
        BRSCH, 
        LOEVM, 
        ZZSUPPLIERKEY, 
        PSA_DELETE_IND
    FROM {{ ref('sat_supplier__winn_sap') }} 
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS DESC)) = 1 
),
SRC_SAT_WINN_P     as ( 
    SELECT 
        SUPPLIER_HK,
        LIFNR, 
        NAME1 
    FROM {{ ref('sat_supplier__winn_sap') }} 
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS DESC)) = 1 
),
SRC_SAT_EBS        as ( 
    SELECT 
        ORGANIZATION_TYPE_LOOKUP_CODE, 
        SUPPLIER_HK, 
        VENDOR_NAME, 
        VENDOR_TYPE_LOOKUP_CODE, 
        SEGMENT1, 
        VENDOR_NAME_ALT, 
        END_DATE_ACTIVE, 
        CREATION_DATE, 
        LAST_UPDATE_DATE, 
        _FIVETRAN_DELETED
    FROM {{ ref('sat_supplier__ml_ebs') }} 
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS DESC)) = 1 
),
SRC_SAT_TT_GP      as ( 
    SELECT 
        SUPPLIER_HK, 
        VENDORID, 
        VENDNAME, 
        VNDCHKNM, 
        VNDCLSID, 
        VENDSTTS, 
        CREATDDT, 
        MODIFDT, 
        PSA_DELETE_IND 
    FROM {{ ref('sat_supplier__tt_gp') }} 
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS DESC)) = 1 
),
SRC_SAT_TT_E21     as ( 
    SELECT 
        SUPPLIER_HK, 
        VEND_NAME, 
        VEND_NAME2, 
        VEND_CATG, 
        VEND_STATUS, 
        VEND_CODE, 
        INACTIVE_DATE, 
        ADD_DATE, 
        UPDATE_DATE, 
        _FIVETRAN_DELETED 
    FROM {{ ref('sat_supplier__tt_e21') }} 
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS DESC)) = 1 
),
SRC_SAT_LRSN_PSFT  as ( 
    SELECT 
        SUPPLIER_HK, 
        VENDOR_STATUS, 
        NAME1, 
        NAME2, 
        VENDOR_CLASS, 
        VENDOR_PERSISTENCE, 
        VENDOR_ID, 
        LAST_ACTIVITY_DT, 
        CREATED_DTTM, 
        LAST_MODIFIED_DATE, 
        _FIVETRAN_DELETED 
    FROM {{ ref('sat_supplier__lrsn_psft') }} 
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS DESC)) = 1 
),
SRC_SAT_EMTK_EBS   as ( 
    SELECT 
        SUPPLIER_HK, 
        VENDOR_NAME, 
        VENDOR_TYPE_LOOKUP_CODE, 
        SEGMENT1, 
        VENDOR_NAME_ALT, 
        END_DATE_ACTIVE, 
        CREATION_DATE, 
        LAST_UPDATE_DATE, 
        _FIVETRAN_DELETED 
    FROM {{ ref('sat_supplier__emtk_ebs') }} 
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS DESC)) = 1 
)

/*
SRC_H              as ( SELECT * FROM RAW_VAULT.hub_supplier_v2 )
SRC_SAT_WINN       as ( SELECT * FROM RAW_VAULT.sat_supplier__winn_sap )
SRC_SAT_WINN_P     as ( SELECT * FROM RAW_VAULT.sat_supplier__winn_sap )
SRC_SAT_EBS        as ( SELECT * FROM RAW_VAULT.sat_supplier__ml_ebs )
SRC_SAT_TT_GP      as ( SELECT * FROM RAW_VAULT.sat_supplier__tt_gp )
SRC_SAT_TT_E21     as ( SELECT * FROM RAW_VAULT.sat_supplier__tt_e21 )
SRC_SAT_LRSN_PSFT  as ( SELECT * FROM RAW_VAULT.sat_supplier__lrsn_psft )
SRC_SAT_EMTK_EBS   as ( SELECT * FROM RAW_VAULT.sat_supplier__emtk_ebs )
*/
---- LOGIC LAYER ----

, LOGIC_H as (
    SELECT
        'PIT_SUPPLIER'                                               as                                        PIT_REC_SRC
      , CURRENT_DATE                                                 as                                       SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , SUPPLIER_HK
      , SUPPLIER_BK
      , REC_SRC
      , BKCC
    FROM SRC_H
)

, LOGIC_SAT_WINN as (
    SELECT
        SUPPLIER_HK                                                  as                               SAT_WINN_SUPPLIER_HK
      , NAME1
      , KTOKK
      , LIFNR
      , NAME2
      , BRSCH
      , LOEVM
      , ZZSUPPLIERKEY
      , PSA_DELETE_IND                                               as                            SAT_WINN_PSA_DELETE_IND
    FROM SRC_SAT_WINN
)

, LOGIC_SAT_WINN_P as (
    SELECT
        LTRIM(lifnr, '0')                                            as                                         DRVD_LIFNR
      , NAME1                                                        as                                       WINN_P_NAME1
    FROM SRC_SAT_WINN_P
)

, LOGIC_SAT_EBS as (
    SELECT
        ORGANIZATION_TYPE_LOOKUP_CODE                                as                                  ORGANIZATION_TYPE
      , SUPPLIER_HK                                                  as                                SAT_EBS_SUPPLIER_HK
      , VENDOR_NAME
      , VENDOR_TYPE_LOOKUP_CODE
      , SEGMENT1
      , IFF(_FIVETRAN_DELETED = 'TRUE', 'Y', 'N')                    as                                  _FIVETRAN_DELETED
      , VENDOR_NAME_ALT
      , END_DATE_ACTIVE
      , CREATION_DATE
      , LAST_UPDATE_DATE
    FROM SRC_SAT_EBS
)

, LOGIC_SAT_TT_GP as (
    SELECT
        SUPPLIER_HK                                                  as                              SAT_TT_GP_SUPPLIER_HK
      , VENDORID
      , VENDNAME
      , VNDCHKNM
      , VNDCLSID
      , VENDSTTS::TEXT                                               as                                           VENDSTTS
      , CREATDDT
      , MODIFDT
      , PSA_DELETE_IND                                               as                           SAT_TT_GP_PSA_DELETE_IND
    FROM SRC_SAT_TT_GP
)

, LOGIC_SAT_TT_E21 as (
    SELECT
        SUPPLIER_HK                                                  as                             SAT_TT_E21_SUPPLIER_HK
      , VEND_NAME
      , VEND_NAME2
      , VEND_CATG
      , VEND_STATUS
      , VEND_CODE
      , INACTIVE_DATE
      , ADD_DATE
      , UPDATE_DATE
      , IFF(_FIVETRAN_DELETED = 'TRUE', 'Y', 'N')                    as                        SAT_TT_E21_FIVETRAN_DELETED
    FROM SRC_SAT_TT_E21
)

, LOGIC_SAT_LRSN_PSFT as (
    SELECT
        SUPPLIER_HK                                                  as                          SAT_LRSN_PSFT_SUPPLIER_HK
      , VENDOR_STATUS
      , NAME1                                                        as                                         LRSN_NAME1
      , NAME2                                                        as                                         LRSN_NAME2
      , VENDOR_CLASS
      , VENDOR_PERSISTENCE
      , VENDOR_ID
      , LAST_ACTIVITY_DT
      , CREATED_DTTM
      , LAST_MODIFIED_DATE
      , IFF(_FIVETRAN_DELETED = 'TRUE', 'Y', 'N')                    as                     SAT_LRSN_PSFT_FIVETRAN_DELETED
    FROM SRC_SAT_LRSN_PSFT
)

, LOGIC_SAT_EMTK_EBS as (
    SELECT
        SUPPLIER_HK                                                  as                           SAT_EMTK_EBS_SUPPLIER_HK
      , VENDOR_NAME                                                  as                           SAT_EMTK_EBS_VENDOR_NAME
      , VENDOR_TYPE_LOOKUP_CODE                                      as               SAT_EMTK_EBS_VENDOR_TYPE_LOOKUP_CODE
      , SEGMENT1                                                     as                              SAT_EMTK_EBS_SEGMENT1
      , IFF(_FIVETRAN_DELETED = 'TRUE', 'Y', 'N')                    as                     SAT_EMTK_EBS__FIVETRAN_DELETED
      , VENDOR_NAME_ALT                                              as                       SAT_EMTK_EBS_VENDOR_NAME_ALT
      , END_DATE_ACTIVE                                              as                       SAT_EMTK_EBS_END_DATE_ACTIVE
      , CREATION_DATE                                                as                         SAT_EMTK_EBS_CREATION_DATE
      , LAST_UPDATE_DATE                                             as                      SAT_EMTK_EBS_LAST_UPDATE_DATE
    FROM SRC_SAT_EMTK_EBS
)
---- RENAME LAYER ----

, RENAME_H as (
    SELECT
        PIT_REC_SRC
      , SNAPSHOTDATE
      , PIT_LOAD_DTS
      , SUPPLIER_HK
      , SUPPLIER_BK
      , REC_SRC
      , BKCC
    FROM LOGIC_H
)

, RENAME_SAT_EBS as (
    SELECT
        ORGANIZATION_TYPE
      , SAT_EBS_SUPPLIER_HK
      , VENDOR_NAME
      , VENDOR_TYPE_LOOKUP_CODE
      , SEGMENT1
      , _FIVETRAN_DELETED
      , VENDOR_NAME_ALT
      , END_DATE_ACTIVE
      , CREATION_DATE
      , LAST_UPDATE_DATE
    FROM LOGIC_SAT_EBS
)

, RENAME_SAT_WINN as (
    SELECT
        SAT_WINN_SUPPLIER_HK
      , NAME1
      , KTOKK
      , LIFNR
      , NAME2
      , BRSCH
      , LOEVM
      , ZZSUPPLIERKEY
      , SAT_WINN_PSA_DELETE_IND
    FROM LOGIC_SAT_WINN
)

, RENAME_SAT_LRSN_PSFT as (
    SELECT
        SAT_LRSN_PSFT_SUPPLIER_HK
      , VENDOR_STATUS
      , LRSN_NAME1
      , LRSN_NAME2
      , VENDOR_CLASS
      , VENDOR_PERSISTENCE
      , VENDOR_ID
      , LAST_ACTIVITY_DT
      , CREATED_DTTM
      , LAST_MODIFIED_DATE
      , SAT_LRSN_PSFT_FIVETRAN_DELETED
    FROM LOGIC_SAT_LRSN_PSFT
)

, RENAME_SAT_TT_GP as (
    SELECT
        SAT_TT_GP_SUPPLIER_HK
      , VENDORID
      , VENDNAME
      , VNDCHKNM
      , VNDCLSID
      , VENDSTTS
      , CREATDDT
      , MODIFDT
      , SAT_TT_GP_PSA_DELETE_IND
    FROM LOGIC_SAT_TT_GP
)

, RENAME_SAT_TT_E21 as (
    SELECT
        SAT_TT_E21_SUPPLIER_HK
      , VEND_NAME
      , VEND_NAME2
      , VEND_CATG
      , VEND_STATUS
      , VEND_CODE
      , INACTIVE_DATE
      , ADD_DATE
      , UPDATE_DATE
      , SAT_TT_E21_FIVETRAN_DELETED
    FROM LOGIC_SAT_TT_E21
)

, RENAME_SAT_EMTK_EBS as (
    SELECT
        SAT_EMTK_EBS_SUPPLIER_HK
      , SAT_EMTK_EBS_VENDOR_NAME
      , SAT_EMTK_EBS_VENDOR_TYPE_LOOKUP_CODE
      , SAT_EMTK_EBS_SEGMENT1
      , SAT_EMTK_EBS__FIVETRAN_DELETED
      , SAT_EMTK_EBS_VENDOR_NAME_ALT
      , SAT_EMTK_EBS_END_DATE_ACTIVE
      , SAT_EMTK_EBS_CREATION_DATE
      , SAT_EMTK_EBS_LAST_UPDATE_DATE
    FROM LOGIC_SAT_EMTK_EBS
)

, RENAME_SAT_WINN_P as (
    SELECT
        DRVD_LIFNR
      , WINN_P_NAME1
    FROM LOGIC_SAT_WINN_P
)
---- FILTER LAYER ----

, FILTER_H as (
    SELECT *
    FROM RENAME_H
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED' and BKCC <> 'Laying_Goose'  /* This filter is to exclude the ghost records and mdm data */
)

, FILTER_SAT_WINN as (
    SELECT *
    FROM RENAME_SAT_WINN
)

, FILTER_SAT_WINN_P as (
    SELECT *
    FROM RENAME_SAT_WINN_P
)

, FILTER_SAT_EBS as (
    SELECT *
    FROM RENAME_SAT_EBS
)

, FILTER_SAT_TT_GP as (
    SELECT *
    FROM RENAME_SAT_TT_GP
)

, FILTER_SAT_TT_E21 as (
    SELECT *
    FROM RENAME_SAT_TT_E21
)

, FILTER_SAT_LRSN_PSFT as (
    SELECT *
    FROM RENAME_SAT_LRSN_PSFT
)

, FILTER_SAT_EMTK_EBS as (
    SELECT *
    FROM RENAME_SAT_EMTK_EBS
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_H
    LEFT JOIN FILTER_SAT_WINN
        ON FILTER_H.SUPPLIER_HK = SAT_WINN_SUPPLIER_HK
    LEFT JOIN FILTER_SAT_EBS
        ON FILTER_H.SUPPLIER_HK = SAT_EBS_SUPPLIER_HK
    LEFT JOIN FILTER_SAT_TT_GP
        ON FILTER_H.SUPPLIER_HK = SAT_TT_GP_SUPPLIER_HK
    LEFT JOIN FILTER_SAT_TT_E21
        ON FILTER_H.SUPPLIER_HK = SAT_TT_E21_SUPPLIER_HK
    LEFT JOIN FILTER_SAT_LRSN_PSFT
        ON FILTER_H.SUPPLIER_HK = SAT_LRSN_PSFT_SUPPLIER_HK
    LEFT JOIN FILTER_SAT_EMTK_EBS
        ON FILTER_H.SUPPLIER_HK = SAT_EMTK_EBS_SUPPLIER_HK
    LEFT JOIN FILTER_SAT_WINN_P
        ON FILTER_SAT_WINN.ZZSUPPLIERKEY = FILTER_SAT_WINN_P.DRVD_LIFNR
)

---- FINAL LAYER ----
SELECT
          PIT_REC_SRC
        , SNAPSHOTDATE
        , PIT_LOAD_DTS
        , SUPPLIER_HK
        , SUPPLIER_BK
        , COALESCE(NAME1,VENDOR_NAME,VEND_NAME,VENDNAME,LRSN_NAME1,SAT_EMTK_EBS_VENDOR_NAME) as SUPPLIER_NAME_1
        , COALESCE(NAME2,VEND_NAME2,LRSN_NAME2)                        as SUPPLIER_NAME_2
        , COALESCE(VENDOR_NAME_ALT,VNDCHKNM,SAT_EMTK_EBS_VENDOR_NAME_ALT) as SUPPLIER_ALT_NAME
        , COALESCE(BRSCH,VEND_CATG,VENDOR_CLASS)                       as INDUSTRY_TYPE
        , COALESCE(KTOKK,VENDOR_TYPE_LOOKUP_CODE,VNDCLSID,VENDOR_PERSISTENCE,SAT_EMTK_EBS_VENDOR_TYPE_LOOKUP_CODE) as SUPPLIER_TYPE
        , COALESCE(LOEVM,VEND_STATUS,VENDSTTS,VENDOR_STATUS)           as SUPPLIER_STATUS
        , COALESCE(ZZSUPPLIERKEY,SEGMENT1,VEND_CODE,VENDORID,VENDOR_ID,SAT_EMTK_EBS_SEGMENT1) as PARENT_SUPPLIER_KEY
        , COALESCE(WINN_P_NAME1,VENDOR_NAME,VEND_NAME,VENDNAME,LRSN_NAME1,SAT_EMTK_EBS_VENDOR_NAME) as PARENT_SUPPLIER_NAME
        , ORGANIZATION_TYPE
        , COALESCE(LIFNR,SEGMENT1, VEND_CODE,VENDORID,VENDOR_ID,SAT_EMTK_EBS_SEGMENT1) as SUPPLIER_NUMBER
        , TO_CHAR(COALESCE(END_DATE_ACTIVE,INACTIVE_DATE,LAST_ACTIVITY_DT,SAT_EMTK_EBS_END_DATE_ACTIVE), 'YYYYMMDD')::INTEGER as INACTIVATION_DATE__YYYYMMDD
        , TO_CHAR(COALESCE(CREATION_DATE,ADD_DATE,CREATDDT,CREATED_DTTM,SAT_EMTK_EBS_CREATION_DATE), 'YYYYMMDD')::INTEGER as SOURCE_CREATION_DATE__YYYYMMDD
        , TO_CHAR(COALESCE(LAST_UPDATE_DATE,UPDATE_DATE,MODIFDT,LAST_MODIFIED_DATE,SAT_EMTK_EBS_LAST_UPDATE_DATE), 'YYYYMMDD')::INTEGER as SOURCE_LAST_UPDATE_DATE__YYYYMMDD
        , COALESCE(_FIVETRAN_DELETED,SAT_TT_E21_FIVETRAN_DELETED,SAT_WINN_PSA_DELETE_IND,SAT_TT_GP_PSA_DELETE_IND,SAT_LRSN_PSFT_FIVETRAN_DELETED,SAT_EMTK_EBS__FIVETRAN_DELETED) as IS_DELETED
        , REC_SRC
        , BKCC
FROM JOIN_RESULT
-- Exclude suppliers with NULL or empty names to ensure only valid, named suppliers are included in the PIT table.
WHERE (NULLIF(SUPPLIER_NAME_1,'') IS NOT NULL) 
