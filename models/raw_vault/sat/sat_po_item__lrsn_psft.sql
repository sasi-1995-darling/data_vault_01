---- SRC LAYER ----
WITH
SRC_ps_po_line     as ( SELECT * FROM {{ ref('v_psa_stg_po_item__lrsn_psft') }} as SRC 
                         {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   )

/*
SRC_ps_po_line     as ( SELECT * FROM staging.v_psa_stg_po_item__lrsn_psft )
*/
---- LOGIC LAYER ----

, LOGIC_ps_po_line as (
    SELECT
        PO_ITEM_HK
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
      , HASHDIFF
    FROM SRC_ps_po_line
)
---- RENAME LAYER ----

, RENAME_ps_po_line as (
    SELECT
        PO_ITEM_HK
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
      , HASHDIFF
    FROM LOGIC_ps_po_line
)
---- FILTER LAYER ----

, FILTER_ps_po_line as (
    SELECT *
    FROM RENAME_ps_po_line
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_ps_po_line
)

---- FINAL LAYER ----
SELECT
          PO_ITEM_HK
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
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PO_ITEM_HK = JOIN_RESULT.PO_ITEM_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by PO_ITEM_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS PO_ITEM_HK,
GR.VALUE::text AS BUSINESS_UNIT,
GR.VALUE::text AS PO_ID,
GR.VALUE::text AS LINE_NBR,
NULL AS CANCEL_STATUS,
NULL AS CHANGE_STATUS,
NULL AS ITM_SETID,
NULL AS INV_ITEM_ID,
NULL AS ITM_ID_VNDR,
NULL AS VNDR_CATALOG_ID,
NULL AS CATEGORY_ID,
NULL AS CHNG_ORD_SEQ,
NULL AS UNIT_OF_MEASURE,
NULL AS QTY_TYPE,
NULL AS PRICE_DT_TYPE,
NULL AS MFG_ID,
NULL AS MFG_ITM_ID,
NULL AS CNTRCT_SETID,
NULL AS CNTRCT_ID,
NULL AS CNTRCT_LINE_NBR,
NULL AS RELEASE_NBR,
NULL AS MILESTONE_NBR,
NULL AS CNTRCT_RATE_MULT,
NULL AS CNTRCT_RATE_DIV,
NULL AS VRBT_ID,
NULL AS RFQ_ID,
NULL AS RFQ_LINE_NBR,
NULL AS INSPECT_CD,
NULL AS ROUTING_ID,
NULL AS RECV_REQ,
NULL AS PRICE_CAN_CHANGE,
NULL AS WTHD_SW,
NULL AS WTHD_CD,
NULL AS CONFIG_CODE,
NULL AS CP_TEMPLATE_ID,
NULL AS DESCR254_MIXED,
NULL AS PACKING_WEIGHT,
NULL AS PACKING_VOLUME,
NULL AS UNIT_MEASURE_WT,
NULL AS UNIT_MEASURE_VOL,
NULL AS REPLEN_OPT,
NULL AS AMT_ONLY_FLG,
NULL AS PHYSICAL_NATURE,
NULL AS USER_LINE_CHAR1,
NULL AS GPO_ID,
NULL AS GPO_CNTRCT_NBR,
NULL AS BENEFIT_ID,
NULL AS CNTRCT_CF_LOCK,
NULL AS VERSION_NBR,
NULL AS CAT_LINE_NBR,
NULL AS ORIG_INV_ITEM_ID,
NULL AS DESCR254_MIXED2,
NULL AS CUSTOM_C100_B1,
NULL AS CUSTOM_C100_B2,
NULL AS CUSTOM_C100_B3,
NULL AS CUSTOM_C100_B4,
NULL AS CUSTOM_DATE_B,
NULL AS CUSTOM_C1_B,
NULL AS CLOSE_SHORT_FLG,
NULL AS AUC_GROUP_ID,
NULL AS APPR_REQD,
NULL AS PO_GROUP_ID,
NULL AS PRIMARY_UNIT,
NULL AS UNIT_ALLOC_QTY,
NULL AS UNIT_ALLOC_AMT,
NULL AS UPN_TYPE_CD,
NULL AS UPN_ID,
NULL AS LN_TYPE,
NULL AS _FIVETRAN_DELETED,
NULL AS _FIVETRAN_ID,
NULL AS _FIVETRAN_SYNCED,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
