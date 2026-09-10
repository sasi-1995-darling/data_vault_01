---- SRC LAYER ----
WITH
SRC_gp             as ( SELECT ACPURIDX, APPYTYPE, CAPITAL_ITEM, COSTCODE, COSTTYPE, CURNCYID, CURRNIDX, DATERECD, DENXRATE, DEX_ROW_ID, EXGTBLID, INVINDX, ITEMNMBR, JOBNUMBR, NOTEINDX, OLDCUCST, ORCPTCOST, OREXTCST, OSTDCOST, PCHRPTCT, POLNENUM, PONUMBER, POPRCTNM, POPTYPE, POSTED_LC_PPV_AMOUNT, PRODUCT_INDICATOR, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, QTYINVCD, QTYINVRESERVE, QTYMATCH, QTYREJ, QTYRESERVED, QTYSHPPD, QTYTYPE, RATECALC, RATETPID, RCPTLNNM, RCTSEQNM, RUPPVAMT, SPRCPTCT, SPRCTSEQ, STATUS, TOTAL_LANDED_COST_AMOUNT, TRXLOCTN, UMQTYINB, UOFM, UPPVIDX, VENDORID, XCHGRATE FROM {{ source('tt_gpd', 'dbo_pop10500') }} as SRC  ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_po             as ( SELECT CMPANYID, PONUMBER FROM {{ source('tt_gpd', 'dbo_pop10100') }} as SRC 
                        qualify 1 = row_number()over (partition by ponumber order by psa_load_dts desc) )

/*
SRC_gp             as ( SELECT * FROM tt_gpd.dbo_pop10500 )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_po             as ( SELECT * FROM tt_gpd.dbo_pop10100 )
*/
---- LOGIC LAYER ----

, LOGIC_gp as (
    SELECT
        POPRCTNM
      , RCPTLNNM
      , PONUMBER                                                     as                                       PO_HEADER_BK
      , CONCAT_WS('||', PONUMBER,POLNENUM)                           as                                         PO_ITEM_BK
      , VENDORID                                                     as                                        SUPPLIER_BK
      , ITEMNMBR                                                     as                                            ITEM_BK
      , TRXLOCTN                                                     as                                           PLANT_BK
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
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
    FROM SRC_gp
)

, LOGIC_a as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_a
)

, LOGIC_po as (
    SELECT
        PONUMBER                                                     as                                        PO_PONUMBER
      , CMPANYID
    FROM SRC_po
)
---- RENAME LAYER ----

, RENAME_gp as (
    SELECT
        POPRCTNM
      , RCPTLNNM
      , PO_HEADER_BK
      , PO_ITEM_BK
      , SUPPLIER_BK
      , ITEM_BK
      , PLANT_BK
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
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_gp
)

, RENAME_po as (
    SELECT
        PO_PONUMBER
      , CMPANYID
    FROM LOGIC_po
)

, RENAME_a as (
    SELECT
        BKCC
      , REC_SRC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_gp as (
    SELECT *
    FROM RENAME_gp
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USOHMA.MSSQL.GPPRD.DBO_POP10500'
)

, FILTER_po as (
    SELECT *
    FROM RENAME_po
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_gp
    INNER JOIN FILTER_a
        ON '1' = '1'
    LEFT JOIN FILTER_po
        ON FILTER_gp.PONUMBER = PO_PONUMBER
)

---- FINAL LAYER ----
SELECT
          CONCAT_WS('||'          
          , COALESCE(POPRCTNM,'')
          , COALESCE(RCPTLNNM::TEXT,'')) as PO_ITEM_RECEIPT_BK
        , POPRCTNM
        , RCPTLNNM
        , PO_HEADER_BK
        , PO_ITEM_BK
        , SUPPLIER_BK
        , ITEM_BK
        , PLANT_BK
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
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , /*To handle the optional null default for the Hash key generation and to match with the Ghost Key Hash value */
IFF(TRXLOCTN IS NULL, '-2', CONCAT_WS('||', TRXLOCTN, BKCC)) as DRVD_PLANT_BKCC
        , BKCC
        , REC_SRC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(POPRCTNM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(RCPTLNNM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PONUMBER as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(POLNENUM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(VENDORID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ITEMNMBR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(TRXLOCTN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CMPANYID as VARCHAR)),''), '^^')
        ))) as LNK_PO_RECEIPT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PONUMBER as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_HEADER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PONUMBER as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(POLNENUM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(POPRCTNM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(RCPTLNNM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_ITEM_RECEIPT_DK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VENDORID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEMNMBR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DRVD_PLANT_BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CMPANYID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LEGAL_ENTITY_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(PONUMBER::text), '^^') 
            , '||', IFNULL(TRIM(POLNENUM::text), '^^') 
            , '||', IFNULL(TRIM(QTYSHPPD::text), '^^') 
            , '||', IFNULL(TRIM(QTYINVCD::text), '^^') 
            , '||', IFNULL(TRIM(QTYREJ::text), '^^') 
            , '||', IFNULL(TRIM(QTYMATCH::text), '^^') 
            , '||', IFNULL(TRIM(QTYRESERVED::text), '^^') 
            , '||', IFNULL(TRIM(QTYINVRESERVE::text), '^^') 
            , '||', IFNULL(TRIM(STATUS::text), '^^') 
            , '||', IFNULL(TRIM(UMQTYINB::text), '^^') 
            , '||', IFNULL(TRIM(OLDCUCST::text), '^^') 
            , '||', IFNULL(TRIM(JOBNUMBR::text), '^^') 
            , '||', IFNULL(TRIM(COSTCODE::text), '^^') 
            , '||', IFNULL(TRIM(COSTTYPE::text), '^^') 
            , '||', IFNULL(TRIM(ORCPTCOST::text), '^^') 
            , '||', IFNULL(TRIM(OSTDCOST::text), '^^') 
            , '||', IFNULL(TRIM(APPYTYPE::text), '^^') 
            , '||', IFNULL(TRIM(POPTYPE::text), '^^') 
            , '||', IFNULL(TRIM(VENDORID::text), '^^') 
            , '||', IFNULL(TRIM(ITEMNMBR::text), '^^') 
            , '||', IFNULL(TRIM(UOFM::text), '^^') 
            , '||', IFNULL(TRIM(TRXLOCTN::text), '^^') 
            , '||', IFNULL(TRIM(DATERECD::text), '^^') 
            , '||', IFNULL(TRIM(RCTSEQNM::text), '^^') 
            , '||', IFNULL(TRIM(SPRCTSEQ::text), '^^') 
            , '||', IFNULL(TRIM(PCHRPTCT::text), '^^') 
            , '||', IFNULL(TRIM(SPRCPTCT::text), '^^') 
            , '||', IFNULL(TRIM(OREXTCST::text), '^^') 
            , '||', IFNULL(TRIM(RUPPVAMT::text), '^^') 
            , '||', IFNULL(TRIM(ACPURIDX::text), '^^') 
            , '||', IFNULL(TRIM(INVINDX::text), '^^') 
            , '||', IFNULL(TRIM(UPPVIDX::text), '^^') 
            , '||', IFNULL(TRIM(NOTEINDX::text), '^^') 
            , '||', IFNULL(TRIM(CURNCYID::text), '^^') 
            , '||', IFNULL(TRIM(CURRNIDX::text), '^^') 
            , '||', IFNULL(TRIM(XCHGRATE::text), '^^') 
            , '||', IFNULL(TRIM(RATECALC::text), '^^') 
            , '||', IFNULL(TRIM(DENXRATE::text), '^^') 
            , '||', IFNULL(TRIM(RATETPID::text), '^^') 
            , '||', IFNULL(TRIM(EXGTBLID::text), '^^') 
            , '||', IFNULL(TRIM(CAPITAL_ITEM::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_INDICATOR::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_LANDED_COST_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(QTYTYPE::text), '^^') 
            , '||', IFNULL(TRIM(POSTED_LC_PPV_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
