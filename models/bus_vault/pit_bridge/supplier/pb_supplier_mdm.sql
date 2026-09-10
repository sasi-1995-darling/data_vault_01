---- SRC LAYER ----
WITH
SRC_H              as ( SELECT BKCC, REC_SRC, SUPPLIER_BK, SUPPLIER_HK FROM {{ ref('hub_supplier_v2') }} as SRC  ),
SRC_MDM_HUB_LKUP   as ( SELECT BKCC, REC_SRC, SUPPLIER_HK FROM {{ ref('hub_supplier_v2') }} as SRC 
                        /* This SRC Filter to include only the MDM records to get the equivalent MDM Supplier HK */
                        WHERE BKCC = 'Laying_Goose' ),
SRC_SAT_WINN       as ( SELECT BRSCH, KTOKK, LIFNR, LOEVM, NAME1, NAME2, PSA_DELETE_IND, SUPPLIER_HK, ZZSUPPLIERKEY FROM {{ ref('sat_supplier__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS DESC))=1 ),
SRC_SAT_WINN_P     as ( SELECT LIFNR, NAME1 FROM {{ ref('sat_supplier__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS DESC))=1 ),
SRC_SAT_EBS        as ( SELECT CREATION_DATE, END_DATE_ACTIVE, LAST_UPDATE_DATE, ORGANIZATION_TYPE_LOOKUP_CODE, SEGMENT1, SUPPLIER_HK, VENDOR_NAME, VENDOR_NAME_ALT, VENDOR_TYPE_LOOKUP_CODE, _FIVETRAN_DELETED  FROM {{ ref('sat_supplier__ml_ebs') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS DESC))=1 ),
SRC_SAT_TT_GP      as ( SELECT CREATDDT, MODIFDT, PSA_DELETE_IND, SUPPLIER_HK, VENDNAME, VENDORID, VENDSTTS, VNDCHKNM, VNDCLSID FROM {{ ref('sat_supplier__tt_gp') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS DESC))=1 ),
SRC_SAT_TT_E21     as ( SELECT ADD_DATE, INACTIVE_DATE, SUPPLIER_HK, UPDATE_DATE, VEND_CATG, VEND_CODE, VEND_NAME, VEND_NAME2, VEND_STATUS, _FIVETRAN_DELETED  FROM {{ ref('sat_supplier__tt_e21') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS DESC))=1 ),
SRC_SAT_LRSN_PSFT  as ( SELECT CREATED_DTTM, LAST_ACTIVITY_DT, LAST_MODIFIED_DATE, NAME1, NAME2, SUPPLIER_HK, VENDOR_CLASS, VENDOR_ID, VENDOR_PERSISTENCE, VENDOR_STATUS, _FIVETRAN_DELETED  FROM {{ ref('sat_supplier__lrsn_psft') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS DESC))=1 ),
SRC_SAT_EMTK_EBS   as ( SELECT CREATION_DATE, END_DATE_ACTIVE, LAST_UPDATE_DATE, SEGMENT1, SUPPLIER_HK, VENDOR_NAME, VENDOR_NAME_ALT, VENDOR_TYPE_LOOKUP_CODE, _FIVETRAN_DELETED FROM {{ ref('sat_supplier__emtk_ebs') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS DESC))=1 ),
SRC_LNK            as ( SELECT SAME_AS_SUPPLIER_HK, SLNK_SUPPLIER_HK, SUPPLIER_HK FROM {{ ref('lnk_same_as_supplier') }} as SRC 
                        /* The Following Qualify clause is required to handle the prevailing issue with MDM where Supplier_hk(source) is tied to Two Different Same As Supplier(Golden Record) */
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS DESC))=1 ),
SRC_LSAT_SAMEAS_SPLR as ( SELECT BUSINESS_ID, SLNK_SUPPLIER_HK, SOURCE_PKEY FROM {{ ref('lsat_same_as_supplier') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS DESC))=1 ),
SRC_SAT_MDM        as ( SELECT ALTERNATE_NAME, CREATE_DATE, INACTIVATION_DATE, INDUSTRY_TYPE, LAST_UPDATE_DATE, NAME, OWNERSHIP_TYPE, PSA_DELETE_IND, SUPPLIER_HK, SUPPLIER_ID, SUPPLIER_STATUS FROM {{ ref('sat_supplier_mdm') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS DESC))=1 ),
SRC_SAT_FIB_OCF    as ( SELECT CREATION_DATE, END_DATE_ACTIVE, LAST_UPDATE_DATE, ORGANIZATION_TYPE_LOOKUP_CODE, SEGMENT_1, SUPPLIER_HK, VENDOR_TYPE_LOOKUP_CODE, _FIVETRAN_DELETED FROM {{ ref('sat_supplier__fib_ocf') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS DESC))=1 ),
SRC_SAT_PRTY_FIB_OCF as ( SELECT PARTY_NAME, SUPPLIER_HK FROM {{ ref('sat_supplier_party__fib_ocf') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS DESC))=1 )

/*
SRC_H              as ( SELECT * FROM RAW_VAULT.hub_supplier_v2 )
SRC_MDM_HUB_LKUP   as ( SELECT * FROM RAW_VAULT.hub_supplier_v2 )
SRC_SAT_WINN       as ( SELECT * FROM RAW_VAULT.sat_supplier__winn_sap )
SRC_SAT_WINN_P     as ( SELECT * FROM RAW_VAULT.sat_supplier__winn_sap )
SRC_SAT_EBS        as ( SELECT * FROM RAW_VAULT.sat_supplier__ml_ebs )
SRC_SAT_TT_GP      as ( SELECT * FROM RAW_VAULT.sat_supplier__tt_gp )
SRC_SAT_TT_E21     as ( SELECT * FROM RAW_VAULT.sat_supplier__tt_e21 )
SRC_SAT_LRSN_PSFT  as ( SELECT * FROM RAW_VAULT.sat_supplier__lrsn_psft )
SRC_SAT_EMTK_EBS   as ( SELECT * FROM RAW_VAULT.sat_supplier__emtk_ebs )
SRC_LNK            as ( SELECT * FROM RAW_VAULT.lnk_same_as_supplier )
SRC_LSAT_SAMEAS_SPLR as ( SELECT * FROM RAW_VAULT.lsat_same_as_supplier )
SRC_SAT_MDM        as ( SELECT * FROM RAW_VAULT.sat_supplier_mdm )
SRC_SAT_FIB_OCF    as ( SELECT * FROM RAW_VAULT.sat_supplier__fib_ocf )
SRC_SAT_PRTY_FIB_OCF as ( SELECT * FROM RAW_VAULT.sat_supplier_party__fib_ocf )
*/
---- LOGIC LAYER ----

, LOGIC_H as (
    SELECT
        'PB_SUPPLIER'                                                as                                         PB_REC_SRC
      , CURRENT_DATE                                                 as                                       SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                        PB_LOAD_DTS
      , SUPPLIER_HK
      , SUPPLIER_BK
      , REC_SRC
      , BKCC
    FROM SRC_H
)

, LOGIC_MDM_HUB_LKUP as (
    SELECT
        REC_SRC                                                      as                                        MDM_REC_SRC
      , BKCC                                                         as                                           MDM_BKCC
      , SUPPLIER_HK                                                  as                           MDM_HUB_LKUP_SUPPLIER_HK
    FROM SRC_MDM_HUB_LKUP
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
        NAME1                                                        as                                       WINN_P_NAME1
      , LIFNR                                                        as                                            LIFNR_P
      , LTRIM(LIFNR_P, '0')                                          as                                         DRVD_LIFNR
    FROM SRC_SAT_WINN_P
)

, LOGIC_SAT_EBS as (
    SELECT
        SUPPLIER_HK                                                  as                                SAT_EBS_SUPPLIER_HK
      , VENDOR_NAME
      , VENDOR_TYPE_LOOKUP_CODE
      , SEGMENT1
      , _FIVETRAN_DELETED
      , IFF(_FIVETRAN_DELETED = 'TRUE', 'Y', 'N')                    as                           SAT_EBS_FIVETRAN_DELETED
      , VENDOR_NAME_ALT
      , END_DATE_ACTIVE
      , CREATION_DATE
      , LAST_UPDATE_DATE                                             as                           SAT_EBS_LAST_UPDATE_DATE
      , ORGANIZATION_TYPE_LOOKUP_CODE
    FROM SRC_SAT_EBS
)

, LOGIC_SAT_TT_GP as (
    SELECT
        SUPPLIER_HK                                                  as                              SAT_TT_GP_SUPPLIER_HK
      , VENDORID
      , VENDNAME
      , VNDCHKNM
      , VNDCLSID
      , VENDSTTS
      , VENDSTTS::TEXT                                               as                                 SAT_TT_GP_VENDSTTS
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
      , _FIVETRAN_DELETED
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
      , _FIVETRAN_DELETED
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
      , _FIVETRAN_DELETED
    FROM SRC_SAT_EMTK_EBS
)

, LOGIC_LNK as (
    SELECT
        SAME_AS_SUPPLIER_HK
      , SLNK_SUPPLIER_HK
      , SUPPLIER_HK                                                  as                                    LNK_SUPPLIER_HK
    FROM SRC_LNK
)

, LOGIC_LSAT_SAMEAS_SPLR as (
    SELECT
        BUSINESS_ID                                                  as                                    MDM_SUPPLIER_BK
      , SOURCE_PKEY                                                  as                                    MDM_SOURCE_PKEY
      , SLNK_SUPPLIER_HK                                             as                  LSAT_SAMEAS_SPLR_SLNK_SUPPLIER_HK
    FROM SRC_LSAT_SAMEAS_SPLR
)

, LOGIC_SAT_MDM as (
    SELECT
        NAME                                                         as                                  MDM_SUPPLIER_NAME
      , ALTERNATE_NAME                                               as                              MDM_SUPPLIER_ALT_NAME
      , INDUSTRY_TYPE                                                as                                  MDM_INDUSTRY_TYPE
      , SUPPLIER_STATUS                                              as                                MDM_SUPPLIER_STATUS
      , OWNERSHIP_TYPE                                               as                              MDM_ORGANIZATION_TYPE
      , PSA_DELETE_IND                                               as                                     MDM_IS_DELETED
      , NAME
      , ALTERNATE_NAME
      , OWNERSHIP_TYPE
      , SUPPLIER_ID
      , INACTIVATION_DATE                                            as                              MDM_INACTIVATION_DATE
      , CREATE_DATE
      , LAST_UPDATE_DATE
      , CREATE_DATE::DATE                                            as                                    MDM_CREATE_DATE
      , LAST_UPDATE_DATE::DATE                                       as                               MDM_LAST_UPDATE_DATE
      , SUPPLIER_HK                                                  as                                SAT_MDM_SUPPLIER_HK
    FROM SRC_SAT_MDM
)

, LOGIC_SAT_FIB_OCF as (
    SELECT
        SUPPLIER_HK                                                  as                            SAT_FIB_OCF_SUPPLIER_HK
      , VENDOR_TYPE_LOOKUP_CODE                                      as                SAT_FIB_OCF_VENDOR_TYPE_LOOKUP_CODE
      , ORGANIZATION_TYPE_LOOKUP_CODE                                as          SAT_FIB_OCF_ORGANIZATION_TYPE_LOOKUP_CODE
      , SEGMENT_1                                                    as                               SAT_FIB_OCF_SEGMENT1
      , IFF(_FIVETRAN_DELETED = 'TRUE', 'Y', 'N')                    as                      SAT_FIB_OCF__FIVETRAN_DELETED
      , END_DATE_ACTIVE                                              as                        SAT_FIB_OCF_END_DATE_ACTIVE
      , CREATION_DATE                                                as                          SAT_FIB_OCF_CREATION_DATE
      , LAST_UPDATE_DATE                                             as                       SAT_FIB_OCF_LAST_UPDATE_DATE
      , _FIVETRAN_DELETED
    FROM SRC_SAT_FIB_OCF
)

, LOGIC_SAT_PRTY_FIB_OCF as (
    SELECT
        PARTY_NAME
      , SUPPLIER_HK                                                  as                       SAT_PRTY_FIB_OCF_SUPPLIER_HK
    FROM SRC_SAT_PRTY_FIB_OCF
)
---- RENAME LAYER ----

, RENAME_H as (
    SELECT
        PB_REC_SRC
      , SNAPSHOTDATE
      , PB_LOAD_DTS
      , SUPPLIER_HK
      , SUPPLIER_BK
      , REC_SRC
      , BKCC
    FROM LOGIC_H
)

, RENAME_LNK as (
    SELECT
        SAME_AS_SUPPLIER_HK
      , SLNK_SUPPLIER_HK
      , LNK_SUPPLIER_HK
    FROM LOGIC_LNK
)

, RENAME_LSAT_SAMEAS_SPLR as (
    SELECT
        MDM_SUPPLIER_BK
      , MDM_SOURCE_PKEY
      , LSAT_SAMEAS_SPLR_SLNK_SUPPLIER_HK
    FROM LOGIC_LSAT_SAMEAS_SPLR
)

, RENAME_SAT_MDM as (
    SELECT
        MDM_SUPPLIER_NAME
      , MDM_SUPPLIER_ALT_NAME
      , MDM_INDUSTRY_TYPE
      , MDM_SUPPLIER_STATUS
      , MDM_ORGANIZATION_TYPE
      , MDM_IS_DELETED
      , NAME
      , ALTERNATE_NAME
      , OWNERSHIP_TYPE
      , SUPPLIER_ID
      , MDM_INACTIVATION_DATE
      , CREATE_DATE
      , LAST_UPDATE_DATE
      , MDM_CREATE_DATE
      , MDM_LAST_UPDATE_DATE
      , SAT_MDM_SUPPLIER_HK
    FROM LOGIC_SAT_MDM
)

, RENAME_MDM_HUB_LKUP as (
    SELECT
        MDM_REC_SRC
      , MDM_BKCC
      , MDM_HUB_LKUP_SUPPLIER_HK
    FROM LOGIC_MDM_HUB_LKUP
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

, RENAME_SAT_EBS as (
    SELECT
        SAT_EBS_SUPPLIER_HK
      , VENDOR_NAME
      , VENDOR_TYPE_LOOKUP_CODE
      , SEGMENT1
      , _FIVETRAN_DELETED 
      , SAT_EBS_FIVETRAN_DELETED
      , VENDOR_NAME_ALT
      , END_DATE_ACTIVE
      , CREATION_DATE
      , SAT_EBS_LAST_UPDATE_DATE
      , ORGANIZATION_TYPE_LOOKUP_CODE
    FROM LOGIC_SAT_EBS
)

, RENAME_SAT_TT_GP as (
    SELECT
        SAT_TT_GP_SUPPLIER_HK
      , VENDORID
      , VENDNAME
      , VNDCHKNM
      , VNDCLSID
      , VENDSTTS
      , SAT_TT_GP_VENDSTTS
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
      , _FIVETRAN_DELETED 
      , SAT_TT_E21_FIVETRAN_DELETED
    FROM LOGIC_SAT_TT_E21
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
      , _FIVETRAN_DELETED 
      , SAT_LRSN_PSFT_FIVETRAN_DELETED
    FROM LOGIC_SAT_LRSN_PSFT
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
      , _FIVETRAN_DELETED
    FROM LOGIC_SAT_EMTK_EBS
)

, RENAME_SAT_WINN_P as (
    SELECT
        WINN_P_NAME1
      , LIFNR_P
      , DRVD_LIFNR
    FROM LOGIC_SAT_WINN_P
)

, RENAME_SAT_FIB_OCF as (
    SELECT
        SAT_FIB_OCF_SUPPLIER_HK
      , SAT_FIB_OCF_VENDOR_TYPE_LOOKUP_CODE
      , SAT_FIB_OCF_ORGANIZATION_TYPE_LOOKUP_CODE
      , SAT_FIB_OCF_SEGMENT1
      , SAT_FIB_OCF__FIVETRAN_DELETED
      , SAT_FIB_OCF_END_DATE_ACTIVE
      , SAT_FIB_OCF_CREATION_DATE
      , SAT_FIB_OCF_LAST_UPDATE_DATE
      , _FIVETRAN_DELETED
    FROM LOGIC_SAT_FIB_OCF
)

, RENAME_SAT_PRTY_FIB_OCF as (
    SELECT
        PARTY_NAME
      , SAT_PRTY_FIB_OCF_SUPPLIER_HK
    FROM LOGIC_SAT_PRTY_FIB_OCF
)
---- FILTER LAYER ----

, FILTER_H as (
    SELECT *
    FROM RENAME_H
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'  /* This filter is to exclude the ghost records */
    AND BKCC <> 'Laying_Goose' /* This filter is to exclude the MDM records */
)

, FILTER_MDM_HUB_LKUP as (
    SELECT *
    FROM RENAME_MDM_HUB_LKUP
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

, FILTER_LNK as (
    SELECT *
    FROM RENAME_LNK
)

, FILTER_LSAT_SAMEAS_SPLR as (
    SELECT *
    FROM RENAME_LSAT_SAMEAS_SPLR
)

, FILTER_SAT_MDM as (
    SELECT *
    FROM RENAME_SAT_MDM
)

, FILTER_SAT_FIB_OCF as (
    SELECT *
    FROM RENAME_SAT_FIB_OCF
)

, FILTER_SAT_PRTY_FIB_OCF as (
    SELECT *
    FROM RENAME_SAT_PRTY_FIB_OCF
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
    LEFT JOIN FILTER_LNK
        ON FILTER_H.SUPPLIER_HK = LNK_SUPPLIER_HK
/* The Lnk is not being used as Driver due to the fact that the Lnk has only subset of MDM data, but the intent of this PIT is to have all the Supplier Source data*/
    LEFT JOIN FILTER_SAT_FIB_OCF
        ON FILTER_H.SUPPLIER_HK = SAT_FIB_OCF_SUPPLIER_HK
    LEFT JOIN FILTER_SAT_PRTY_FIB_OCF
        ON FILTER_H.SUPPLIER_HK = SAT_PRTY_FIB_OCF_SUPPLIER_HK
    LEFT JOIN FILTER_MDM_HUB_LKUP
        ON FILTER_LNK.SAME_AS_SUPPLIER_HK = MDM_HUB_LKUP_SUPPLIER_HK
    LEFT JOIN FILTER_SAT_WINN_P
        ON FILTER_SAT_WINN.ZZSUPPLIERKEY = DRVD_LIFNR
    LEFT JOIN FILTER_LSAT_SAMEAS_SPLR
        ON FILTER_LNK.SLNK_SUPPLIER_HK = LSAT_SAMEAS_SPLR_SLNK_SUPPLIER_HK
    LEFT JOIN FILTER_SAT_MDM
        ON MDM_HUB_LKUP_SUPPLIER_HK = SAT_MDM_SUPPLIER_HK
)

---- FINAL LAYER ----
SELECT
          PB_REC_SRC
        , SNAPSHOTDATE
        , PB_LOAD_DTS
        , SUPPLIER_HK
        , SAME_AS_SUPPLIER_HK
        , SUPPLIER_BK
        , MDM_SUPPLIER_BK
        , MDM_SOURCE_PKEY
        , iff(SAME_AS_SUPPLIER_HK IS NULL, 'N', 'Y')                   as MDM_GOLDEN_RECORD
        , MDM_SUPPLIER_NAME
        , MDM_SUPPLIER_ALT_NAME
        , MDM_INDUSTRY_TYPE
        , MDM_SUPPLIER_STATUS
        , MDM_ORGANIZATION_TYPE
        , TO_CHAR(MDM_INACTIVATION_DATE, 'YYYYMMDD')::INTEGER          as MDM_INACTIVATION_DATE__YYYYMMDD
        , TO_CHAR(MDM_CREATE_DATE, 'YYYYMMDD')::INTEGER                as MDM_SOURCE_CREATION_DATE__YYYYMMDD
        , TO_CHAR(MDM_LAST_UPDATE_DATE, 'YYYYMMDD')::INTEGER           as MDM_SOURCE_LAST_UPDATE_DATE__YYYYMMDD
        , MDM_IS_DELETED
        , COALESCE(NAME1,VENDOR_NAME,VEND_NAME,VENDNAME,LRSN_NAME1,SAT_EMTK_EBS_VENDOR_NAME,PARTY_NAME)  as SUPPLIER_NAME_1
        , COALESCE(NAME2,VEND_NAME2,LRSN_NAME2)                        as SUPPLIER_NAME_2
        , COALESCE(VENDOR_NAME_ALT,VNDCHKNM,SAT_EMTK_EBS_VENDOR_NAME_ALT)  as SUPPLIER_ALT_NAME
        , COALESCE(BRSCH,VEND_CATG,VENDOR_CLASS)                       as INDUSTRY_TYPE
        , COALESCE(KTOKK,VENDOR_TYPE_LOOKUP_CODE,VNDCLSID,VENDOR_PERSISTENCE,SAT_EMTK_EBS_VENDOR_TYPE_LOOKUP_CODE,SAT_FIB_OCF_VENDOR_TYPE_LOOKUP_CODE) as SUPPLIER_TYPE
        , COALESCE(LOEVM,VEND_STATUS,SAT_TT_GP_VENDSTTS,VENDOR_STATUS)  as SUPPLIER_STATUS
        , COALESCE(NULLIF(ZZSUPPLIERKEY, ''),SEGMENT1,VEND_CODE,VENDORID,VENDOR_ID,SAT_EMTK_EBS_SEGMENT1,SAT_FIB_OCF_SEGMENT1, '-2') as PARENT_SUPPLIER_KEY
        , COALESCE(WINN_P_NAME1,VENDOR_NAME,VEND_NAME,VENDNAME,LRSN_NAME1,SAT_EMTK_EBS_VENDOR_NAME,PARTY_NAME, '-2') as PARENT_SUPPLIER_NAME
        , COALESCE(ORGANIZATION_TYPE_LOOKUP_CODE, SAT_FIB_OCF_ORGANIZATION_TYPE_LOOKUP_CODE) as ORGANIZATION_TYPE
        , COALESCE(LIFNR,SEGMENT1, VEND_CODE,VENDORID,VENDOR_ID,SAT_EMTK_EBS_SEGMENT1,SAT_FIB_OCF_SEGMENT1) as SUPPLIER_NUMBER
        , TO_CHAR(COALESCE(END_DATE_ACTIVE,INACTIVE_DATE,LAST_ACTIVITY_DT,SAT_EMTK_EBS_END_DATE_ACTIVE,SAT_FIB_OCF_END_DATE_ACTIVE), 'YYYYMMDD')::INTEGER as INACTIVATION_DATE__YYYYMMDD
        , TO_CHAR(COALESCE(CREATION_DATE,ADD_DATE,CREATDDT,CREATED_DTTM,SAT_EMTK_EBS_CREATION_DATE,SAT_FIB_OCF_CREATION_DATE), 'YYYYMMDD')::INTEGER as SOURCE_CREATION_DATE__YYYYMMDD
        , TO_CHAR(COALESCE(SAT_EBS_LAST_UPDATE_DATE,UPDATE_DATE,MODIFDT,LAST_MODIFIED_DATE,SAT_EMTK_EBS_LAST_UPDATE_DATE,SAT_FIB_OCF_LAST_UPDATE_DATE), 'YYYYMMDD')::INTEGER as SOURCE_LAST_UPDATE_DATE__YYYYMMDD
        , COALESCE(SAT_EBS_FIVETRAN_DELETED,SAT_TT_E21_FIVETRAN_DELETED,SAT_WINN_PSA_DELETE_IND,SAT_TT_GP_PSA_DELETE_IND,SAT_LRSN_PSFT_FIVETRAN_DELETED,SAT_EMTK_EBS__FIVETRAN_DELETED,SAT_FIB_OCF__FIVETRAN_DELETED) as IS_DELETED
        , COALESCE(MDM_SUPPLIER_BK,SUPPLIER_BK)                        as UNIFIED_SUPPLIER_KEY
        , COALESCE(MDM_SUPPLIER_NAME,SUPPLIER_NAME_1)                  as UNIFIED_SUPPLIER_NAME
        , REC_SRC
        , BKCC
        , MDM_REC_SRC
        , MDM_BKCC
        , COALESCE(MDM_REC_SRC,REC_SRC)                                as UNIFIED_REC_SRC
        , COALESCE(MDM_BKCC,BKCC)                                      as UNIFIED_BKCC
FROM JOIN_RESULT
/* Exclude suppliers with NULL or empty names to ensure only valid, named suppliers are included in the PIT table.*/
where (NULLIF(supplier_name_1,'') IS NOT NULL)
