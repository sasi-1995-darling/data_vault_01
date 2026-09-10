---- SRC LAYER ----
WITH
SRC_a              as ( 
    SELECT 
        LNK_PO_RECEIPT_HK,
        POPRCTNM,
        RCPTLNNM,
        PONUMBER,
        POLNENUM,
        QTYSHPPD,
        QTYINVCD,
        QTYREJ,
        QTYMATCH,
        QTYRESERVED,
        QTYINVRESERVE,
        STATUS,
        UMQTYINB,
        OLDCUCST,
        JOBNUMBR,
        COSTCODE,
        COSTTYPE,
        ORCPTCOST,
        OSTDCOST,
        APPYTYPE,
        POPTYPE,
        VENDORID,
        ITEMNMBR,
        UOFM,
        TRXLOCTN,
        DATERECD,
        RCTSEQNM,
        SPRCTSEQ,
        PCHRPTCT,
        SPRCPTCT,
        OREXTCST,
        RUPPVAMT,
        ACPURIDX,
        INVINDX,
        UPPVIDX,
        NOTEINDX,
        CURNCYID,
        CURRNIDX,
        XCHGRATE,
        RATECALC,
        DENXRATE,
        RATETPID,
        EXGTBLID,
        CAPITAL_ITEM,
        PRODUCT_INDICATOR,
        TOTAL_LANDED_COST_AMOUNT,
        QTYTYPE,
        POSTED_LC_PPV_AMOUNT,
        DEX_ROW_ID,
        PSA_RECORD_SOURCE,
        PSA_LOAD_DTS,
        PSA_DELETE_IND,
        LOAD_DTS,
        BKCC,
        REC_SRC,
        HASHDIFF
    FROM {{ ref('v_psa_stg_po_receipt__tt_gp') }} as SRC 
    {% if is_incremental() %}
        WHERE src.load_dts > (SELECT dateadd('HOUR',-1,max(load_dts)) FROM {{ this }})
    {% endif %}   
)

/*
SRC_a              as ( SELECT * FROM STAGING.v_psa_stg_po_receipt__tt_gp )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        LNK_PO_RECEIPT_HK
      , POPRCTNM
      , RCPTLNNM
      , PONUMBER
      , POLNENUM
      , QTYSHPPD
      , QTYINVCD
      , QTYREJ
      , QTYMATCH
      , QTYRESERVED
      , QTYINVRESERVE
      , STATUS
      , UMQTYINB
      , OLDCUCST
      , JOBNUMBR
      , COSTCODE
      , COSTTYPE
      , ORCPTCOST
      , OSTDCOST
      , APPYTYPE
      , POPTYPE
      , VENDORID
      , ITEMNMBR
      , UOFM
      , TRXLOCTN
      , DATERECD
      , RCTSEQNM
      , SPRCTSEQ
      , PCHRPTCT
      , SPRCPTCT
      , OREXTCST
      , RUPPVAMT
      , ACPURIDX
      , INVINDX
      , UPPVIDX
      , NOTEINDX
      , CURNCYID
      , CURRNIDX
      , XCHGRATE
      , RATECALC
      , DENXRATE
      , RATETPID
      , EXGTBLID
      , CAPITAL_ITEM
      , PRODUCT_INDICATOR
      , TOTAL_LANDED_COST_AMOUNT
      , QTYTYPE
      , POSTED_LC_PPV_AMOUNT
      , DEX_ROW_ID
      , PSA_RECORD_SOURCE
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , LOAD_DTS
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        LNK_PO_RECEIPT_HK
      , POPRCTNM
      , RCPTLNNM
      , PONUMBER
      , POLNENUM
      , QTYSHPPD
      , QTYINVCD
      , QTYREJ
      , QTYMATCH
      , QTYRESERVED
      , QTYINVRESERVE
      , STATUS
      , UMQTYINB
      , OLDCUCST
      , JOBNUMBR
      , COSTCODE
      , COSTTYPE
      , ORCPTCOST
      , OSTDCOST
      , APPYTYPE
      , POPTYPE
      , VENDORID
      , ITEMNMBR
      , UOFM
      , TRXLOCTN
      , DATERECD
      , RCTSEQNM
      , SPRCTSEQ
      , PCHRPTCT
      , SPRCPTCT
      , OREXTCST
      , RUPPVAMT
      , ACPURIDX
      , INVINDX
      , UPPVIDX
      , NOTEINDX
      , CURNCYID
      , CURRNIDX
      , XCHGRATE
      , RATECALC
      , DENXRATE
      , RATETPID
      , EXGTBLID
      , CAPITAL_ITEM
      , PRODUCT_INDICATOR
      , TOTAL_LANDED_COST_AMOUNT
      , QTYTYPE
      , POSTED_LC_PPV_AMOUNT
      , DEX_ROW_ID
      , PSA_RECORD_SOURCE
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , LOAD_DTS
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
)

---- FINAL LAYER ----
SELECT
          LNK_PO_RECEIPT_HK
        , POPRCTNM
        , RCPTLNNM
        , PONUMBER
        , POLNENUM
        , QTYSHPPD
        , QTYINVCD
        , QTYREJ
        , QTYMATCH
        , QTYRESERVED
        , QTYINVRESERVE
        , STATUS
        , UMQTYINB
        , OLDCUCST
        , JOBNUMBR
        , COSTCODE
        , COSTTYPE
        , ORCPTCOST
        , OSTDCOST
        , APPYTYPE
        , POPTYPE
        , VENDORID
        , ITEMNMBR
        , UOFM
        , TRXLOCTN
        , DATERECD
        , RCTSEQNM
        , SPRCTSEQ
        , PCHRPTCT
        , SPRCPTCT
        , OREXTCST
        , RUPPVAMT
        , ACPURIDX
        , INVINDX
        , UPPVIDX
        , NOTEINDX
        , CURNCYID
        , CURRNIDX
        , XCHGRATE
        , RATECALC
        , DENXRATE
        , RATETPID
        , EXGTBLID
        , CAPITAL_ITEM
        , PRODUCT_INDICATOR
        , TOTAL_LANDED_COST_AMOUNT
        , QTYTYPE
        , POSTED_LC_PPV_AMOUNT
        , DEX_ROW_ID
        , PSA_RECORD_SOURCE
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , LOAD_DTS
        , BKCC
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LNK_PO_RECEIPT_HK = JOIN_RESULT.LNK_PO_RECEIPT_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by LNK_PO_RECEIPT_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS LNK_PO_RECEIPT_HK,
GR.VALUE::text AS POPRCTNM,
GR.VALUE::NUMBER AS RCPTLNNM,
NULL AS PONUMBER,
NULL AS POLNENUM,
NULL AS QTYSHPPD,
NULL AS QTYINVCD,
NULL AS QTYREJ,
NULL AS QTYMATCH,
NULL AS QTYRESERVED,
NULL AS QTYINVRESERVE,
NULL AS STATUS,
NULL AS UMQTYINB,
NULL AS OLDCUCST,
NULL AS JOBNUMBR,
NULL AS COSTCODE,
NULL AS COSTTYPE,
NULL AS ORCPTCOST,
NULL AS OSTDCOST,
NULL AS APPYTYPE,
NULL AS POPTYPE,
NULL AS VENDORID,
NULL AS ITEMNMBR,
NULL AS UOFM,
NULL AS TRXLOCTN,
NULL AS DATERECD,
NULL AS RCTSEQNM,
NULL AS SPRCTSEQ,
NULL AS PCHRPTCT,
NULL AS SPRCPTCT,
NULL AS OREXTCST,
NULL AS RUPPVAMT,
NULL AS ACPURIDX,
NULL AS INVINDX,
NULL AS UPPVIDX,
NULL AS NOTEINDX,
NULL AS CURNCYID,
NULL AS CURRNIDX,
NULL AS XCHGRATE,
NULL AS RATECALC,
NULL AS DENXRATE,
NULL AS RATETPID,
NULL AS EXGTBLID,
NULL AS CAPITAL_ITEM,
NULL AS PRODUCT_INDICATOR,
NULL AS TOTAL_LANDED_COST_AMOUNT,
NULL AS QTYTYPE,
NULL AS POSTED_LC_PPV_AMOUNT,
NULL AS DEX_ROW_ID,
NULL AS PSA_RECORD_SOURCE,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
