---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('lrsn_psft_sysadm', 'ps_vendor') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM lrsn_psft_sysadm.ps_vendor )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        VENDOR_ID::TEXT                                              as                                        SUPPLIER_BK
      , VENDOR_ID
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED )                   as                                           LOAD_DTS
      , SETID
      , VENDOR_NAME_SHORT
      , VNDR_NAME_SHRT_USR
      , VNDR_NAME_SEQ_NUM
      , NAME1
      , NAME2
      , VENDOR_STATUS
      , VENDOR_CLASS
      , VENDOR_PERSISTENCE
      , REMIT_ADDR_SEQ_NUM
      , PRIM_ADDR_SEQ_NUM
      , ADDR_SEQ_NUM_ORDR
      , REMIT_SETID
      , REMIT_VENDOR
      , CORPORATE_SETID
      , CORPORATE_VENDOR
      , CUST_SETID
      , CUST_ID
      , ENTERED_BY
      , AR_NUM
      , OLD_VENDOR_ID
      , WTHD_SW
      , VAT_SW
      , VNDR_STATUS_PO
      , REMIT_LOC
      , DEFAULT_LOC
      , NAME1_AC
      , NAME2_AC
      , PRIMARY_VENDOR
      , LAST_ACTIVITY_DT
      , WITHHOLD_LOC
      , IN_PROCESS_FLG
      , PROCESS_INSTANCE
      , HUB_ZONE
      , EEO_CERTIF_DT
      , HRMS_CLASS
      , INTERUNIT_VNDR_FLG
      , VNDR_AFFILIATE
      , BUSINESS_UNIT
      , VNDR_TIN
      , ARCHIVED_BY
      , CREATED_DTTM
      , CREATED_BY_USER
      , LAST_MODIFIED_DATE
      , VNDR_FIELD_C30_A
      , VNDR_FIELD_C30_B
      , VNDR_FIELD_C30_C
      , VNDR_FIELD_C30_D
      , VNDR_FIELD_C30_E
      , VNDR_FIELD_C30_F
      , VNDR_FIELD_C30_G
      , VNDR_FIELD_C30_H
      , VNDR_FIELD_C30_I
      , VNDR_FIELD_C30_J
      , VNDR_CCR_STATUS
      , OFAC_STATUS
      , OFAC_STATUS_DT
      , OFAC_MOD_USER
      , OFAC_LAG_DAYS
      , OFAC_SKIP_VAL
      , SDN_PUBLISH_DATE
      , SES_LAST_DTTM
      , SES_VN_ATTR_L_DTTM
      , SUPPLIER_RATING
      , SUPPAUDIT_FLG
      , VNDR_AUDIT_FLG
      , TEMPLATE_ID
      , COMMENTS_2000
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
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
        SUPPLIER_BK
      , VENDOR_ID
      , LOAD_DTS
      , SETID
      , VENDOR_NAME_SHORT
      , VNDR_NAME_SHRT_USR
      , VNDR_NAME_SEQ_NUM
      , NAME1
      , NAME2
      , VENDOR_STATUS
      , VENDOR_CLASS
      , VENDOR_PERSISTENCE
      , REMIT_ADDR_SEQ_NUM
      , PRIM_ADDR_SEQ_NUM
      , ADDR_SEQ_NUM_ORDR
      , REMIT_SETID
      , REMIT_VENDOR
      , CORPORATE_SETID
      , CORPORATE_VENDOR
      , CUST_SETID
      , CUST_ID
      , ENTERED_BY
      , AR_NUM
      , OLD_VENDOR_ID
      , WTHD_SW
      , VAT_SW
      , VNDR_STATUS_PO
      , REMIT_LOC
      , DEFAULT_LOC
      , NAME1_AC
      , NAME2_AC
      , PRIMARY_VENDOR
      , LAST_ACTIVITY_DT
      , WITHHOLD_LOC
      , IN_PROCESS_FLG
      , PROCESS_INSTANCE
      , HUB_ZONE
      , EEO_CERTIF_DT
      , HRMS_CLASS
      , INTERUNIT_VNDR_FLG
      , VNDR_AFFILIATE
      , BUSINESS_UNIT
      , VNDR_TIN
      , ARCHIVED_BY
      , CREATED_DTTM
      , CREATED_BY_USER
      , LAST_MODIFIED_DATE
      , VNDR_FIELD_C30_A
      , VNDR_FIELD_C30_B
      , VNDR_FIELD_C30_C
      , VNDR_FIELD_C30_D
      , VNDR_FIELD_C30_E
      , VNDR_FIELD_C30_F
      , VNDR_FIELD_C30_G
      , VNDR_FIELD_C30_H
      , VNDR_FIELD_C30_I
      , VNDR_FIELD_C30_J
      , VNDR_CCR_STATUS
      , OFAC_STATUS
      , OFAC_STATUS_DT
      , OFAC_MOD_USER
      , OFAC_LAG_DAYS
      , OFAC_SKIP_VAL
      , SDN_PUBLISH_DATE
      , SES_LAST_DTTM
      , SES_VN_ATTR_L_DTTM
      , SUPPLIER_RATING
      , SUPPAUDIT_FLG
      , VNDR_AUDIT_FLG
      , TEMPLATE_ID
      , COMMENTS_2000
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
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
    WHERE rec_src = 'USSDBR.ORCL.PSFTPRD.PS_VENDOR'
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
          SUPPLIER_BK
        , VENDOR_ID
        , LOAD_DTS
        , SETID
        , VENDOR_NAME_SHORT
        , VNDR_NAME_SHRT_USR
        , VNDR_NAME_SEQ_NUM
        , NAME1
        , NAME2
        , VENDOR_STATUS
        , VENDOR_CLASS
        , VENDOR_PERSISTENCE
        , REMIT_ADDR_SEQ_NUM
        , PRIM_ADDR_SEQ_NUM
        , ADDR_SEQ_NUM_ORDR
        , REMIT_SETID
        , REMIT_VENDOR
        , CORPORATE_SETID
        , CORPORATE_VENDOR
        , CUST_SETID
        , CUST_ID
        , ENTERED_BY
        , AR_NUM
        , OLD_VENDOR_ID
        , WTHD_SW
        , VAT_SW
        , VNDR_STATUS_PO
        , REMIT_LOC
        , DEFAULT_LOC
        , NAME1_AC
        , NAME2_AC
        , PRIMARY_VENDOR
        , LAST_ACTIVITY_DT
        , WITHHOLD_LOC
        , IN_PROCESS_FLG
        , PROCESS_INSTANCE
        , HUB_ZONE
        , EEO_CERTIF_DT
        , HRMS_CLASS
        , INTERUNIT_VNDR_FLG
        , VNDR_AFFILIATE
        , BUSINESS_UNIT
        , VNDR_TIN
        , ARCHIVED_BY
        , CREATED_DTTM
        , CREATED_BY_USER
        , LAST_MODIFIED_DATE
        , VNDR_FIELD_C30_A
        , VNDR_FIELD_C30_B
        , VNDR_FIELD_C30_C
        , VNDR_FIELD_C30_D
        , VNDR_FIELD_C30_E
        , VNDR_FIELD_C30_F
        , VNDR_FIELD_C30_G
        , VNDR_FIELD_C30_H
        , VNDR_FIELD_C30_I
        , VNDR_FIELD_C30_J
        , VNDR_CCR_STATUS
        , OFAC_STATUS
        , OFAC_STATUS_DT
        , OFAC_MOD_USER
        , OFAC_LAG_DAYS
        , OFAC_SKIP_VAL
        , SDN_PUBLISH_DATE
        , SES_LAST_DTTM
        , SES_VN_ATTR_L_DTTM
        , SUPPLIER_RATING
        , SUPPAUDIT_FLG
        , VNDR_AUDIT_FLG
        , TEMPLATE_ID
        , COMMENTS_2000
        , _FIVETRAN_DELETED
        , _FIVETRAN_ID
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VENDOR_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(VENDOR_NAME_SHORT::text), '^^') 
            , '||', IFNULL(TRIM(VNDR_NAME_SHRT_USR::text), '^^') 
            , '||', IFNULL(TRIM(VNDR_NAME_SEQ_NUM::text), '^^') 
            , '||', IFNULL(TRIM(NAME1::text), '^^') 
            , '||', IFNULL(TRIM(NAME2::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_CLASS::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_PERSISTENCE::text), '^^') 
            , '||', IFNULL(TRIM(REMIT_ADDR_SEQ_NUM::text), '^^') 
            , '||', IFNULL(TRIM(PRIM_ADDR_SEQ_NUM::text), '^^') 
            , '||', IFNULL(TRIM(ADDR_SEQ_NUM_ORDR::text), '^^') 
            , '||', IFNULL(TRIM(REMIT_SETID::text), '^^') 
            , '||', IFNULL(TRIM(REMIT_VENDOR::text), '^^') 
            , '||', IFNULL(TRIM(CORPORATE_SETID::text), '^^') 
            , '||', IFNULL(TRIM(CORPORATE_VENDOR::text), '^^') 
            , '||', IFNULL(TRIM(CUST_SETID::text), '^^') 
            , '||', IFNULL(TRIM(CUST_ID::text), '^^') 
            , '||', IFNULL(TRIM(ENTERED_BY::text), '^^') 
            , '||', IFNULL(TRIM(AR_NUM::text), '^^') 
            , '||', IFNULL(TRIM(OLD_VENDOR_ID::text), '^^') 
            , '||', IFNULL(TRIM(WTHD_SW::text), '^^') 
            , '||', IFNULL(TRIM(VAT_SW::text), '^^') 
            , '||', IFNULL(TRIM(VNDR_STATUS_PO::text), '^^') 
            , '||', IFNULL(TRIM(REMIT_LOC::text), '^^') 
            , '||', IFNULL(TRIM(DEFAULT_LOC::text), '^^') 
            , '||', IFNULL(TRIM(NAME1_AC::text), '^^') 
            , '||', IFNULL(TRIM(NAME2_AC::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_VENDOR::text), '^^') 
            , '||', IFNULL(TRIM(LAST_ACTIVITY_DT::text), '^^') 
            , '||', IFNULL(TRIM(WITHHOLD_LOC::text), '^^') 
            , '||', IFNULL(TRIM(IN_PROCESS_FLG::text), '^^') 
            , '||', IFNULL(TRIM(PROCESS_INSTANCE::text), '^^') 
            , '||', IFNULL(TRIM(HUB_ZONE::text), '^^') 
            , '||', IFNULL(TRIM(EEO_CERTIF_DT::text), '^^') 
            , '||', IFNULL(TRIM(HRMS_CLASS::text), '^^') 
            , '||', IFNULL(TRIM(INTERUNIT_VNDR_FLG::text), '^^') 
            , '||', IFNULL(TRIM(VNDR_AFFILIATE::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(VNDR_TIN::text), '^^') 
            , '||', IFNULL(TRIM(ARCHIVED_BY::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_DTTM::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY_USER::text), '^^') 
            , '||', IFNULL(TRIM(LAST_MODIFIED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(VNDR_FIELD_C30_A::text), '^^') 
            , '||', IFNULL(TRIM(VNDR_FIELD_C30_B::text), '^^') 
            , '||', IFNULL(TRIM(VNDR_FIELD_C30_C::text), '^^') 
            , '||', IFNULL(TRIM(VNDR_FIELD_C30_D::text), '^^') 
            , '||', IFNULL(TRIM(VNDR_FIELD_C30_E::text), '^^') 
            , '||', IFNULL(TRIM(VNDR_FIELD_C30_F::text), '^^') 
            , '||', IFNULL(TRIM(VNDR_FIELD_C30_G::text), '^^') 
            , '||', IFNULL(TRIM(VNDR_FIELD_C30_H::text), '^^') 
            , '||', IFNULL(TRIM(VNDR_FIELD_C30_I::text), '^^') 
            , '||', IFNULL(TRIM(VNDR_FIELD_C30_J::text), '^^') 
            , '||', IFNULL(TRIM(VNDR_CCR_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(OFAC_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(OFAC_STATUS_DT::text), '^^') 
            , '||', IFNULL(TRIM(OFAC_MOD_USER::text), '^^') 
            , '||', IFNULL(TRIM(OFAC_LAG_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(OFAC_SKIP_VAL::text), '^^') 
            , '||', IFNULL(TRIM(SDN_PUBLISH_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SES_LAST_DTTM::text), '^^') 
            , '||', IFNULL(TRIM(SES_VN_ATTR_L_DTTM::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLIER_RATING::text), '^^') 
            , '||', IFNULL(TRIM(SUPPAUDIT_FLG::text), '^^') 
            , '||', IFNULL(TRIM(VNDR_AUDIT_FLG::text), '^^') 
            , '||', IFNULL(TRIM(TEMPLATE_ID::text), '^^') 
            , '||', IFNULL(TRIM(COMMENTS_2000::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
