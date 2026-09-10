---- SRC LAYER ----
WITH
SRC_ps_po_line     as ( SELECT * FROM {{ source('lrsn_psft_sysadm', 'ps_po_line') }} as SRC  ),
SRC_ps_po_hdr      as ( SELECT * FROM {{ source('lrsn_psft_sysadm', 'ps_po_hdr') }} as SRC 
                        qualify 1= row_number()over(partition by po_id, business_unit order by _fivetran_synced desc, psa_load_dts desc) ),
SRC_a              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_ps_po_line     as ( SELECT * FROM lrsn_psft_sysadm.ps_po_line )
, SRC_ps_po_hdr      as ( SELECT * FROM lrsn_psft_sysadm.ps_po_hdr )
, SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_ps_po_line as (
    SELECT
        CONCAT_WS('||', COALESCE(BUSINESS_UNIT, ''), COALESCE(PO_ID, ''), COALESCE(LINE_NBR, '')) as                                         PO_ITEM_BK
      , CONCAT_WS('||', BUSINESS_UNIT,PO_ID)                         as                                       PO_HEADER_BK
      , COALESCE(INV_ITEM_ID::TEXT, '')                              as                                            ITEM_BK
      , COALESCE(BUSINESS_UNIT::TEXT, '')                            as                                    LEGAL_ENTITY_BK
      , BUSINESS_UNIT
      , PO_ID
      , COALESCE(LINE_NBR::TEXT, '')                                 as                                           LINE_NBR
      , CANCEL_STATUS
      , CHANGE_STATUS
      , ITM_SETID
      , INV_ITEM_ID
      , ITM_ID_VNDR
      , VNDR_CATALOG_ID
      , CATEGORY_ID::TEXT                                            as                                        CATEGORY_ID
      , CHNG_ORD_SEQ
      , UNIT_OF_MEASURE
      , QTY_TYPE
      , PRICE_DT_TYPE
      , MFG_ID
      , MFG_ITM_ID
      , CNTRCT_SETID
      , CNTRCT_ID
      , CNTRCT_LINE_NBR
      , RELEASE_NBR
      , MILESTONE_NBR
      , CNTRCT_RATE_MULT
      , CNTRCT_RATE_DIV
      , VRBT_ID
      , RFQ_ID
      , RFQ_LINE_NBR
      , INSPECT_CD
      , ROUTING_ID
      , RECV_REQ
      , PRICE_CAN_CHANGE
      , WTHD_SW
      , WTHD_CD
      , CONFIG_CODE
      , CP_TEMPLATE_ID
      , DESCR254_MIXED
      , PACKING_WEIGHT
      , PACKING_VOLUME
      , UNIT_MEASURE_WT
      , UNIT_MEASURE_VOL
      , REPLEN_OPT
      , AMT_ONLY_FLG
      , PHYSICAL_NATURE
      , USER_LINE_CHAR1
      , GPO_ID
      , GPO_CNTRCT_NBR
      , BENEFIT_ID
      , CNTRCT_CF_LOCK
      , VERSION_NBR
      , CAT_LINE_NBR
      , ORIG_INV_ITEM_ID
      , DESCR254_MIXED2
      , CUSTOM_C100_B1
      , CUSTOM_C100_B2
      , CUSTOM_C100_B3
      , CUSTOM_C100_B4
      , CUSTOM_DATE_B
      , CUSTOM_C1_B
      , CLOSE_SHORT_FLG
      , AUC_GROUP_ID
      , APPR_REQD
      , PO_GROUP_ID
      , PRIMARY_UNIT
      , UNIT_ALLOC_QTY
      , UNIT_ALLOC_AMT
      , UPN_TYPE_CD
      , UPN_ID
      , LN_TYPE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
    FROM SRC_ps_po_line
)

, LOGIC_ps_po_hdr as (
    SELECT
        PO_ID                                                        as                                          HDR_PO_ID
      , VENDOR_ID
      , BUSINESS_UNIT                                                as                            ps_po_hdr_BUSINESS_UNIT
    FROM SRC_ps_po_hdr
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_ps_po_line as (
    SELECT
        PO_ITEM_BK
      , PO_HEADER_BK
      , ITEM_BK
      , LEGAL_ENTITY_BK
      , BUSINESS_UNIT
      , PO_ID
      , LINE_NBR
      , CANCEL_STATUS
      , CHANGE_STATUS
      , ITM_SETID
      , INV_ITEM_ID
      , ITM_ID_VNDR
      , VNDR_CATALOG_ID
      , CATEGORY_ID
      , CHNG_ORD_SEQ
      , UNIT_OF_MEASURE
      , QTY_TYPE
      , PRICE_DT_TYPE
      , MFG_ID
      , MFG_ITM_ID
      , CNTRCT_SETID
      , CNTRCT_ID
      , CNTRCT_LINE_NBR
      , RELEASE_NBR
      , MILESTONE_NBR
      , CNTRCT_RATE_MULT
      , CNTRCT_RATE_DIV
      , VRBT_ID
      , RFQ_ID
      , RFQ_LINE_NBR
      , INSPECT_CD
      , ROUTING_ID
      , RECV_REQ
      , PRICE_CAN_CHANGE
      , WTHD_SW
      , WTHD_CD
      , CONFIG_CODE
      , CP_TEMPLATE_ID
      , DESCR254_MIXED
      , PACKING_WEIGHT
      , PACKING_VOLUME
      , UNIT_MEASURE_WT
      , UNIT_MEASURE_VOL
      , REPLEN_OPT
      , AMT_ONLY_FLG
      , PHYSICAL_NATURE
      , USER_LINE_CHAR1
      , GPO_ID
      , GPO_CNTRCT_NBR
      , BENEFIT_ID
      , CNTRCT_CF_LOCK
      , VERSION_NBR
      , CAT_LINE_NBR
      , ORIG_INV_ITEM_ID
      , DESCR254_MIXED2
      , CUSTOM_C100_B1
      , CUSTOM_C100_B2
      , CUSTOM_C100_B3
      , CUSTOM_C100_B4
      , CUSTOM_DATE_B
      , CUSTOM_C1_B
      , CLOSE_SHORT_FLG
      , AUC_GROUP_ID
      , APPR_REQD
      , PO_GROUP_ID
      , PRIMARY_UNIT
      , UNIT_ALLOC_QTY
      , UNIT_ALLOC_AMT
      , UPN_TYPE_CD
      , UPN_ID
      , LN_TYPE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_ps_po_line
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)

, RENAME_ps_po_hdr as (
    SELECT
        HDR_PO_ID
      , VENDOR_ID
      , ps_po_hdr_BUSINESS_UNIT
    FROM LOGIC_ps_po_hdr
)
---- FILTER LAYER ----

, FILTER_ps_po_line as (
    SELECT *
    FROM RENAME_ps_po_line
)

, FILTER_ps_po_hdr as (
    SELECT *
    FROM RENAME_ps_po_hdr
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USSDBR.ORCL.PSFTPRD.PS_PO_LINE'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_ps_po_line
    LEFT JOIN FILTER_ps_po_hdr
        ON FILTER_ps_po_line.PO_ID = FILTER_ps_po_hdr.HDR_PO_ID and business_unit = ps_po_hdr_business_unit
    INNER JOIN FILTER_a
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          PO_ITEM_BK
        , PO_HEADER_BK
        , COALESCE(VENDOR_ID::TEXT, '')                                as SUPPLIER_BK
        , ITEM_BK
        , LEGAL_ENTITY_BK
        , BUSINESS_UNIT
        , PO_ID
        , LINE_NBR
        , CANCEL_STATUS
        , CHANGE_STATUS
        , ITM_SETID
        , INV_ITEM_ID
        , ITM_ID_VNDR
        , VNDR_CATALOG_ID
        , CATEGORY_ID
        , CHNG_ORD_SEQ
        , UNIT_OF_MEASURE
        , QTY_TYPE
        , PRICE_DT_TYPE
        , MFG_ID
        , MFG_ITM_ID
        , CNTRCT_SETID
        , CNTRCT_ID
        , CNTRCT_LINE_NBR
        , RELEASE_NBR
        , MILESTONE_NBR
        , CNTRCT_RATE_MULT
        , CNTRCT_RATE_DIV
        , VRBT_ID
        , RFQ_ID
        , RFQ_LINE_NBR
        , INSPECT_CD
        , ROUTING_ID
        , RECV_REQ
        , PRICE_CAN_CHANGE
        , WTHD_SW
        , WTHD_CD
        , CONFIG_CODE
        , CP_TEMPLATE_ID
        , DESCR254_MIXED
        , PACKING_WEIGHT
        , PACKING_VOLUME
        , UNIT_MEASURE_WT
        , UNIT_MEASURE_VOL
        , REPLEN_OPT
        , AMT_ONLY_FLG
        , PHYSICAL_NATURE
        , USER_LINE_CHAR1
        , GPO_ID
        , GPO_CNTRCT_NBR
        , BENEFIT_ID
        , CNTRCT_CF_LOCK
        , VERSION_NBR
        , CAT_LINE_NBR
        , ORIG_INV_ITEM_ID
        , DESCR254_MIXED2
        , CUSTOM_C100_B1
        , CUSTOM_C100_B2
        , CUSTOM_C100_B3
        , CUSTOM_C100_B4
        , CUSTOM_DATE_B
        , CUSTOM_C1_B
        , CLOSE_SHORT_FLG
        , AUC_GROUP_ID
        , APPR_REQD
        , PO_GROUP_ID
        , PRIMARY_UNIT
        , UNIT_ALLOC_QTY
        , UNIT_ALLOC_AMT
        , UPN_TYPE_CD
        , UPN_ID
        , LN_TYPE
        , _FIVETRAN_DELETED
        , _FIVETRAN_ID
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , HDR_PO_ID
        , VENDOR_ID
        , PS_PO_HDR_BUSINESS_UNIT
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BUSINESS_UNIT as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PO_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(LINE_NBR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BUSINESS_UNIT as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PO_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_HEADER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VENDOR_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INV_ITEM_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BUSINESS_UNIT as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LEGAL_ENTITY_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PO_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(LINE_NBR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(VENDOR_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(INV_ITEM_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BUSINESS_UNIT as VARCHAR)),''), '^^')
        ))) as LNK_PO_ITEM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(CANCEL_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(CHANGE_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(ITM_SETID::text), '^^') 
            , '||', IFNULL(TRIM(INV_ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(ITM_ID_VNDR::text), '^^') 
            , '||', IFNULL(TRIM(VNDR_CATALOG_ID::text), '^^') 
            , '||', IFNULL(TRIM(CATEGORY_ID::text), '^^') 
            , '||', IFNULL(TRIM(CHNG_ORD_SEQ::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_OF_MEASURE::text), '^^') 
            , '||', IFNULL(TRIM(QTY_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_DT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(MFG_ID::text), '^^') 
            , '||', IFNULL(TRIM(MFG_ITM_ID::text), '^^') 
            , '||', IFNULL(TRIM(CNTRCT_SETID::text), '^^') 
            , '||', IFNULL(TRIM(CNTRCT_ID::text), '^^') 
            , '||', IFNULL(TRIM(CNTRCT_LINE_NBR::text), '^^') 
            , '||', IFNULL(TRIM(RELEASE_NBR::text), '^^') 
            , '||', IFNULL(TRIM(MILESTONE_NBR::text), '^^') 
            , '||', IFNULL(TRIM(CNTRCT_RATE_MULT::text), '^^') 
            , '||', IFNULL(TRIM(CNTRCT_RATE_DIV::text), '^^') 
            , '||', IFNULL(TRIM(VRBT_ID::text), '^^') 
            , '||', IFNULL(TRIM(RFQ_ID::text), '^^') 
            , '||', IFNULL(TRIM(RFQ_LINE_NBR::text), '^^') 
            , '||', IFNULL(TRIM(INSPECT_CD::text), '^^') 
            , '||', IFNULL(TRIM(ROUTING_ID::text), '^^') 
            , '||', IFNULL(TRIM(RECV_REQ::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_CAN_CHANGE::text), '^^') 
            , '||', IFNULL(TRIM(WTHD_SW::text), '^^') 
            , '||', IFNULL(TRIM(WTHD_CD::text), '^^') 
            , '||', IFNULL(TRIM(CONFIG_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CP_TEMPLATE_ID::text), '^^') 
            , '||', IFNULL(TRIM(DESCR254_MIXED::text), '^^') 
            , '||', IFNULL(TRIM(PACKING_WEIGHT::text), '^^') 
            , '||', IFNULL(TRIM(PACKING_VOLUME::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_MEASURE_WT::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_MEASURE_VOL::text), '^^') 
            , '||', IFNULL(TRIM(REPLEN_OPT::text), '^^') 
            , '||', IFNULL(TRIM(AMT_ONLY_FLG::text), '^^') 
            , '||', IFNULL(TRIM(PHYSICAL_NATURE::text), '^^') 
            , '||', IFNULL(TRIM(USER_LINE_CHAR1::text), '^^') 
            , '||', IFNULL(TRIM(GPO_ID::text), '^^') 
            , '||', IFNULL(TRIM(GPO_CNTRCT_NBR::text), '^^') 
            , '||', IFNULL(TRIM(BENEFIT_ID::text), '^^') 
            , '||', IFNULL(TRIM(CNTRCT_CF_LOCK::text), '^^') 
            , '||', IFNULL(TRIM(VERSION_NBR::text), '^^') 
            , '||', IFNULL(TRIM(CAT_LINE_NBR::text), '^^') 
            , '||', IFNULL(TRIM(ORIG_INV_ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(DESCR254_MIXED2::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_C100_B1::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_C100_B2::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_C100_B3::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_C100_B4::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_DATE_B::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_C1_B::text), '^^') 
            , '||', IFNULL(TRIM(CLOSE_SHORT_FLG::text), '^^') 
            , '||', IFNULL(TRIM(AUC_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(APPR_REQD::text), '^^') 
            , '||', IFNULL(TRIM(PO_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_ALLOC_QTY::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_ALLOC_AMT::text), '^^') 
            , '||', IFNULL(TRIM(UPN_TYPE_CD::text), '^^') 
            , '||', IFNULL(TRIM(UPN_ID::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
            , '||', IFNULL(TRIM(PS_PO_HDR_BUSINESS_UNIT::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
