---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('tt_gpd', 'dbo_iv00102') }} as SRC 
                        /*The following where clause is required to filter the data for site-specific records only and exclude overall records (totals for all sites) and exclude duplicates coming from deleted records in the source system for typo/error plant bk = 'FT WAYNE' (FTWAYNE w/ no space is the correct bk and has no duplicates)*/ 
                        where rcrdtype = 2 and locncode not in ('FT WAYNE')
                        /*The following qualify clause is required to pick the first entered record to resolve an issue with the great plains tables in PSA where duplicate records are being loaded for every table every day */
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY ITEMNMBR, LOCNCODE ORDER BY PSA_LOAD_DTS) ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM tt_gpd.dbo_iv00102 )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        coalesce(nullif(trim(ITEMNMBR), ''), '-1')                   as                                            ITEM_BK
      , ITEMNMBR
      , LOCNCODE
      , BINNMBR
      , RCRDTYPE
      , PRIMVNDR
      , ITMFRFLG
      , BGNGQTY
      , LSORDQTY
      , LRCPTQTY
      , LSTORDDT
      , LSORDVND
      , LSRCPTDT
      , QTYRQSTN
      , QTYONORD
      , QTYBKORD
      , QTY_DROP_SHIPPED
      , QTYINUSE
      , QTYINSVC
      , QTYRTRND
      , QTYDMGED
      , QTYONHND
      , ATYALLOC
      , QTYCOMTD
      , QTYSOLD
      , NXTCNTDT
      , NXTCNTTM
      , LSTCNTDT
      , LSTCNTTM
      , STCKCNTINTRVL
      , LANDED_COST_GROUP_ID
      , BUYERID
      , PLANNERID
      , ORDERPOLICY
      , FXDORDRQTY
      , ORDRPNTQTY
      , NMBROFDYS
      , MNMMORDRQTY
      , MXMMORDRQTY
      , ORDERMULTIPLE
      , REPLENISHMENTMETHOD
      , SHRINKAGEFACTOR
      , PRCHSNGLDTM
      , MNFCTRNGFXDLDTM
      , MNFCTRNGVRBLLDTM
      , STAGINGLDTME
      , PLNNNGTMFNCDYS
      , DMNDTMFNCPRDS
      , INCLDDINPLNNNG
      , CALCULATEATP
      , AUTOCHKATP
      , PLNFNLPAB
      , FRCSTCNSMPTNPRD
      , ORDRUPTOLVL
      , SFTYSTCKQTY
      , REORDERVARIANCE
      , PORECEIPTBIN
      , PORETRNBIN
      , SOFULFILLMENTBIN
      , SORETURNBIN
      , BOMRCPTBIN
      , MATERIALISSUEBIN
      , MORECEIPTBIN
      , REPAIRISSUESBIN
      , REPLENISHMENTLEVEL
      , POPORDERMETHOD
      , MASTERLOCATIONCODE
      , POPVENDORSELECTION
      , POPPRICINGSELECTION
      , PURCHASEPRICE
      , INCLUDEALLOCATIONS
      , INCLUDEBACKORDERS
      , INCLUDEREQUISITIONS
      , PICKTICKETITEMOPT
      , DEX_ROW_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
      , coalesce(nullif(trim(LOCNCODE), ''), '-1')                   as                                           PLANT_BK
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
      , ITEMNMBR
      , LOCNCODE
      , BINNMBR
      , RCRDTYPE
      , PRIMVNDR
      , ITMFRFLG
      , BGNGQTY
      , LSORDQTY
      , LRCPTQTY
      , LSTORDDT
      , LSORDVND
      , LSRCPTDT
      , QTYRQSTN
      , QTYONORD
      , QTYBKORD
      , QTY_DROP_SHIPPED
      , QTYINUSE
      , QTYINSVC
      , QTYRTRND
      , QTYDMGED
      , QTYONHND
      , ATYALLOC
      , QTYCOMTD
      , QTYSOLD
      , NXTCNTDT
      , NXTCNTTM
      , LSTCNTDT
      , LSTCNTTM
      , STCKCNTINTRVL
      , LANDED_COST_GROUP_ID
      , BUYERID
      , PLANNERID
      , ORDERPOLICY
      , FXDORDRQTY
      , ORDRPNTQTY
      , NMBROFDYS
      , MNMMORDRQTY
      , MXMMORDRQTY
      , ORDERMULTIPLE
      , REPLENISHMENTMETHOD
      , SHRINKAGEFACTOR
      , PRCHSNGLDTM
      , MNFCTRNGFXDLDTM
      , MNFCTRNGVRBLLDTM
      , STAGINGLDTME
      , PLNNNGTMFNCDYS
      , DMNDTMFNCPRDS
      , INCLDDINPLNNNG
      , CALCULATEATP
      , AUTOCHKATP
      , PLNFNLPAB
      , FRCSTCNSMPTNPRD
      , ORDRUPTOLVL
      , SFTYSTCKQTY
      , REORDERVARIANCE
      , PORECEIPTBIN
      , PORETRNBIN
      , SOFULFILLMENTBIN
      , SORETURNBIN
      , BOMRCPTBIN
      , MATERIALISSUEBIN
      , MORECEIPTBIN
      , REPAIRISSUESBIN
      , REPLENISHMENTLEVEL
      , POPORDERMETHOD
      , MASTERLOCATIONCODE
      , POPVENDORSELECTION
      , POPPRICINGSELECTION
      , PURCHASEPRICE
      , INCLUDEALLOCATIONS
      , INCLUDEBACKORDERS
      , INCLUDEREQUISITIONS
      , PICKTICKETITEMOPT
      , DEX_ROW_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , PLANT_BK
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
    WHERE rec_src = 'USOHMA.MSSQL.GPPRD.DBO_IV00102'
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
        , ITEMNMBR
        , LOCNCODE
        , BINNMBR
        , RCRDTYPE
        , PRIMVNDR
        , ITMFRFLG
        , BGNGQTY
        , LSORDQTY
        , LRCPTQTY
        , LSTORDDT
        , LSORDVND
        , LSRCPTDT
        , QTYRQSTN
        , QTYONORD
        , QTYBKORD
        , QTY_DROP_SHIPPED
        , QTYINUSE
        , QTYINSVC
        , QTYRTRND
        , QTYDMGED
        , QTYONHND
        , ATYALLOC
        , QTYCOMTD
        , QTYSOLD
        , NXTCNTDT
        , NXTCNTTM
        , LSTCNTDT
        , LSTCNTTM
        , STCKCNTINTRVL
        , LANDED_COST_GROUP_ID
        , BUYERID
        , PLANNERID
        , ORDERPOLICY
        , FXDORDRQTY
        , ORDRPNTQTY
        , NMBROFDYS
        , MNMMORDRQTY
        , MXMMORDRQTY
        , ORDERMULTIPLE
        , REPLENISHMENTMETHOD
        , SHRINKAGEFACTOR
        , PRCHSNGLDTM
        , MNFCTRNGFXDLDTM
        , MNFCTRNGVRBLLDTM
        , STAGINGLDTME
        , PLNNNGTMFNCDYS
        , DMNDTMFNCPRDS
        , INCLDDINPLNNNG
        , CALCULATEATP
        , AUTOCHKATP
        , PLNFNLPAB
        , FRCSTCNSMPTNPRD
        , ORDRUPTOLVL
        , SFTYSTCKQTY
        , REORDERVARIANCE
        , PORECEIPTBIN
        , PORETRNBIN
        , SOFULFILLMENTBIN
        , SORETURNBIN
        , BOMRCPTBIN
        , MATERIALISSUEBIN
        , MORECEIPTBIN
        , REPAIRISSUESBIN
        , REPLENISHMENTLEVEL
        , POPORDERMETHOD
        , MASTERLOCATIONCODE
        , POPVENDORSELECTION
        , POPPRICINGSELECTION
        , PURCHASEPRICE
        , INCLUDEALLOCATIONS
        , INCLUDEBACKORDERS
        , INCLUDEREQUISITIONS
        , PICKTICKETITEMOPT
        , DEX_ROW_ID
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , PLANT_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_ITEM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ITEMNMBR::text), '^^') 
            , '||', IFNULL(TRIM(LOCNCODE::text), '^^') 
            , '||', IFNULL(TRIM(BINNMBR::text), '^^') 
            , '||', IFNULL(TRIM(RCRDTYPE::text), '^^') 
            , '||', IFNULL(TRIM(PRIMVNDR::text), '^^') 
            , '||', IFNULL(TRIM(ITMFRFLG::text), '^^') 
            , '||', IFNULL(TRIM(BGNGQTY::text), '^^') 
            , '||', IFNULL(TRIM(LSORDQTY::text), '^^') 
            , '||', IFNULL(TRIM(LRCPTQTY::text), '^^') 
            , '||', IFNULL(TRIM(LSTORDDT::text), '^^') 
            , '||', IFNULL(TRIM(LSORDVND::text), '^^') 
            , '||', IFNULL(TRIM(LSRCPTDT::text), '^^') 
            , '||', IFNULL(TRIM(QTYRQSTN::text), '^^') 
            , '||', IFNULL(TRIM(QTYONORD::text), '^^') 
            , '||', IFNULL(TRIM(QTYBKORD::text), '^^') 
            , '||', IFNULL(TRIM(QTY_DROP_SHIPPED::text), '^^') 
            , '||', IFNULL(TRIM(QTYINUSE::text), '^^') 
            , '||', IFNULL(TRIM(QTYINSVC::text), '^^') 
            , '||', IFNULL(TRIM(QTYRTRND::text), '^^') 
            , '||', IFNULL(TRIM(QTYDMGED::text), '^^') 
            , '||', IFNULL(TRIM(QTYONHND::text), '^^') 
            , '||', IFNULL(TRIM(ATYALLOC::text), '^^') 
            , '||', IFNULL(TRIM(QTYCOMTD::text), '^^') 
            , '||', IFNULL(TRIM(QTYSOLD::text), '^^') 
            , '||', IFNULL(TRIM(NXTCNTDT::text), '^^') 
            , '||', IFNULL(TRIM(NXTCNTTM::text), '^^') 
            , '||', IFNULL(TRIM(LSTCNTDT::text), '^^') 
            , '||', IFNULL(TRIM(LSTCNTTM::text), '^^') 
            , '||', IFNULL(TRIM(STCKCNTINTRVL::text), '^^') 
            , '||', IFNULL(TRIM(LANDED_COST_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(BUYERID::text), '^^') 
            , '||', IFNULL(TRIM(PLANNERID::text), '^^') 
            , '||', IFNULL(TRIM(ORDERPOLICY::text), '^^') 
            , '||', IFNULL(TRIM(FXDORDRQTY::text), '^^') 
            , '||', IFNULL(TRIM(ORDRPNTQTY::text), '^^') 
            , '||', IFNULL(TRIM(NMBROFDYS::text), '^^') 
            , '||', IFNULL(TRIM(MNMMORDRQTY::text), '^^') 
            , '||', IFNULL(TRIM(MXMMORDRQTY::text), '^^') 
            , '||', IFNULL(TRIM(ORDERMULTIPLE::text), '^^') 
            , '||', IFNULL(TRIM(REPLENISHMENTMETHOD::text), '^^') 
            , '||', IFNULL(TRIM(SHRINKAGEFACTOR::text), '^^') 
            , '||', IFNULL(TRIM(PRCHSNGLDTM::text), '^^') 
            , '||', IFNULL(TRIM(MNFCTRNGFXDLDTM::text), '^^') 
            , '||', IFNULL(TRIM(MNFCTRNGVRBLLDTM::text), '^^') 
            , '||', IFNULL(TRIM(STAGINGLDTME::text), '^^') 
            , '||', IFNULL(TRIM(PLNNNGTMFNCDYS::text), '^^') 
            , '||', IFNULL(TRIM(DMNDTMFNCPRDS::text), '^^') 
            , '||', IFNULL(TRIM(INCLDDINPLNNNG::text), '^^') 
            , '||', IFNULL(TRIM(CALCULATEATP::text), '^^') 
            , '||', IFNULL(TRIM(AUTOCHKATP::text), '^^') 
            , '||', IFNULL(TRIM(PLNFNLPAB::text), '^^') 
            , '||', IFNULL(TRIM(FRCSTCNSMPTNPRD::text), '^^') 
            , '||', IFNULL(TRIM(ORDRUPTOLVL::text), '^^') 
            , '||', IFNULL(TRIM(SFTYSTCKQTY::text), '^^') 
            , '||', IFNULL(TRIM(REORDERVARIANCE::text), '^^') 
            , '||', IFNULL(TRIM(PORECEIPTBIN::text), '^^') 
            , '||', IFNULL(TRIM(PORETRNBIN::text), '^^') 
            , '||', IFNULL(TRIM(SOFULFILLMENTBIN::text), '^^') 
            , '||', IFNULL(TRIM(SORETURNBIN::text), '^^') 
            , '||', IFNULL(TRIM(BOMRCPTBIN::text), '^^') 
            , '||', IFNULL(TRIM(MATERIALISSUEBIN::text), '^^') 
            , '||', IFNULL(TRIM(MORECEIPTBIN::text), '^^') 
            , '||', IFNULL(TRIM(REPAIRISSUESBIN::text), '^^') 
            , '||', IFNULL(TRIM(REPLENISHMENTLEVEL::text), '^^') 
            , '||', IFNULL(TRIM(POPORDERMETHOD::text), '^^') 
            , '||', IFNULL(TRIM(MASTERLOCATIONCODE::text), '^^') 
            , '||', IFNULL(TRIM(POPVENDORSELECTION::text), '^^') 
            , '||', IFNULL(TRIM(POPPRICINGSELECTION::text), '^^') 
            , '||', IFNULL(TRIM(PURCHASEPRICE::text), '^^') 
            , '||', IFNULL(TRIM(INCLUDEALLOCATIONS::text), '^^') 
            , '||', IFNULL(TRIM(INCLUDEBACKORDERS::text), '^^') 
            , '||', IFNULL(TRIM(INCLUDEREQUISITIONS::text), '^^') 
            , '||', IFNULL(TRIM(PICKTICKETITEMOPT::text), '^^') 
            , '||', IFNULL(TRIM(DEX_ROW_ID::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
