---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('tt_gpd', 'dbo_iv00101') }} as SRC 
                        /*The following qualify clause is required to pick the first entered record to resolve an issue with the great plains tables in PSA where duplicate records are being loaded for every table every day */
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY ITEMNMBR ORDER BY PSA_LOAD_DTS) ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM tt_gpd.dbo_iv00101 )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        coalesce(nullif(trim(ITEMNMBR), ''), '-1')                   as                                            ITEM_BK
      , ITEMNMBR
      , ITEMDESC
      , NOTEINDX
      , ITMSHNAM
      , ITEMTYPE
      , ITMGEDSC
      , STNDCOST
      , CURRCOST
      , ITEMSHWT
      , DECPLQTY
      , DECPLCUR
      , ITMTSHID
      , TAXOPTNS
      , IVIVINDX
      , IVIVOFIX
      , IVCOGSIX
      , IVSLSIDX
      , IVSLDSIX
      , IVSLRNIX
      , IVINUSIX
      , IVINSVIX
      , IVDMGIDX
      , IVVARIDX
      , DPSHPIDX
      , PURPVIDX
      , UPPVIDX
      , IVRETIDX
      , ASMVRIDX
      , ITMCLSCD
      , ITMTRKOP
      , LOTTYPE
      , KPERHIST
      , KPTRXHST
      , KPCALHST
      , KPDSTHST
      , ALWBKORD
      , VCTNMTHD
      , UOMSCHDL
      , ALTITEM1
      , ALTITEM2
      , USCATVLS_1
      , USCATVLS_2
      , USCATVLS_3
      , USCATVLS_4
      , USCATVLS_5
      , USCATVLS_6
      , MSTRCDTY
      , MODIFDT
      , CREATDDT
      , WRNTYDYS
      , PRCLEVEL
      , LOCNCODE
      , PINFLIDX
      , PURMCIDX
      , IVINFIDX
      , INVMCIDX
      , CGSINFLX
      , CGSMCIDX
      , ITEMCODE
      , TCC
      , PRICEGROUP
      , PRICMTHD
      , PRCHSUOM
      , SELNGUOM
      , KTACCTSR
      , LASTGENSN
      , ABCCODE
      , REVALUE_INVENTORY
      , TOLERANCE_PERCENTAGE
      , PURCHASE_ITEM_TAX_SCHEDU
      , PURCHASE_TAX_OPTIONS
      , ITMPLNNNGTYP
      , STTSTCLVLPRCNTG
      , CNTRYORGN
      , INACTIVE
      , MINSHELF1
      , MINSHELF2
      , INCLUDEINDP
      , DEX_ROW_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS )                       as                                           LOAD_DTS
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
      , ITEMDESC
      , NOTEINDX
      , ITMSHNAM
      , ITEMTYPE
      , ITMGEDSC
      , STNDCOST
      , CURRCOST
      , ITEMSHWT
      , DECPLQTY
      , DECPLCUR
      , ITMTSHID
      , TAXOPTNS
      , IVIVINDX
      , IVIVOFIX
      , IVCOGSIX
      , IVSLSIDX
      , IVSLDSIX
      , IVSLRNIX
      , IVINUSIX
      , IVINSVIX
      , IVDMGIDX
      , IVVARIDX
      , DPSHPIDX
      , PURPVIDX
      , UPPVIDX
      , IVRETIDX
      , ASMVRIDX
      , ITMCLSCD
      , ITMTRKOP
      , LOTTYPE
      , KPERHIST
      , KPTRXHST
      , KPCALHST
      , KPDSTHST
      , ALWBKORD
      , VCTNMTHD
      , UOMSCHDL
      , ALTITEM1
      , ALTITEM2
      , USCATVLS_1
      , USCATVLS_2
      , USCATVLS_3
      , USCATVLS_4
      , USCATVLS_5
      , USCATVLS_6
      , MSTRCDTY
      , MODIFDT
      , CREATDDT
      , WRNTYDYS
      , PRCLEVEL
      , LOCNCODE
      , PINFLIDX
      , PURMCIDX
      , IVINFIDX
      , INVMCIDX
      , CGSINFLX
      , CGSMCIDX
      , ITEMCODE
      , TCC
      , PRICEGROUP
      , PRICMTHD
      , PRCHSUOM
      , SELNGUOM
      , KTACCTSR
      , LASTGENSN
      , ABCCODE
      , REVALUE_INVENTORY
      , TOLERANCE_PERCENTAGE
      , PURCHASE_ITEM_TAX_SCHEDU
      , PURCHASE_TAX_OPTIONS
      , ITMPLNNNGTYP
      , STTSTCLVLPRCNTG
      , CNTRYORGN
      , INACTIVE
      , MINSHELF1
      , MINSHELF2
      , INCLUDEINDP
      , DEX_ROW_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
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
    WHERE rec_src = 'USOHMA.MSSQL.GPPRD.DBO_IV00101'
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
        , ITEMDESC
        , NOTEINDX
        , ITMSHNAM
        , ITEMTYPE
        , ITMGEDSC
        , STNDCOST
        , CURRCOST
        , ITEMSHWT
        , DECPLQTY
        , DECPLCUR
        , ITMTSHID
        , TAXOPTNS
        , IVIVINDX
        , IVIVOFIX
        , IVCOGSIX
        , IVSLSIDX
        , IVSLDSIX
        , IVSLRNIX
        , IVINUSIX
        , IVINSVIX
        , IVDMGIDX
        , IVVARIDX
        , DPSHPIDX
        , PURPVIDX
        , UPPVIDX
        , IVRETIDX
        , ASMVRIDX
        , ITMCLSCD
        , ITMTRKOP
        , LOTTYPE
        , KPERHIST
        , KPTRXHST
        , KPCALHST
        , KPDSTHST
        , ALWBKORD
        , VCTNMTHD
        , UOMSCHDL
        , ALTITEM1
        , ALTITEM2
        , USCATVLS_1
        , USCATVLS_2
        , USCATVLS_3
        , USCATVLS_4
        , USCATVLS_5
        , USCATVLS_6
        , MSTRCDTY
        , MODIFDT
        , CREATDDT
        , WRNTYDYS
        , PRCLEVEL
        , LOCNCODE
        , PINFLIDX
        , PURMCIDX
        , IVINFIDX
        , INVMCIDX
        , CGSINFLX
        , CGSMCIDX
        , ITEMCODE
        , TCC
        , PRICEGROUP
        , PRICMTHD
        , PRCHSUOM
        , SELNGUOM
        , KTACCTSR
        , LASTGENSN
        , ABCCODE
        , REVALUE_INVENTORY
        , TOLERANCE_PERCENTAGE
        , PURCHASE_ITEM_TAX_SCHEDU
        , PURCHASE_TAX_OPTIONS
        , ITMPLNNNGTYP
        , STTSTCLVLPRCNTG
        , CNTRYORGN
        , INACTIVE
        , MINSHELF1
        , MINSHELF2
        , INCLUDEINDP
        , DEX_ROW_ID
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , coalesce(nullif(trim(LOCNCODE), ''), '-2')                   as PLANT_BK
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
              IFNULL(TRIM(ITEMDESC::text), '^^') 
            , '||', IFNULL(TRIM(NOTEINDX::text), '^^') 
            , '||', IFNULL(TRIM(ITMSHNAM::text), '^^') 
            , '||', IFNULL(TRIM(ITEMTYPE::text), '^^') 
            , '||', IFNULL(TRIM(ITMGEDSC::text), '^^') 
            , '||', IFNULL(TRIM(STNDCOST::text), '^^') 
            , '||', IFNULL(TRIM(CURRCOST::text), '^^') 
            , '||', IFNULL(TRIM(ITEMSHWT::text), '^^') 
            , '||', IFNULL(TRIM(DECPLQTY::text), '^^') 
            , '||', IFNULL(TRIM(DECPLCUR::text), '^^') 
            , '||', IFNULL(TRIM(ITMTSHID::text), '^^') 
            , '||', IFNULL(TRIM(TAXOPTNS::text), '^^') 
            , '||', IFNULL(TRIM(IVIVINDX::text), '^^') 
            , '||', IFNULL(TRIM(IVIVOFIX::text), '^^') 
            , '||', IFNULL(TRIM(IVCOGSIX::text), '^^') 
            , '||', IFNULL(TRIM(IVSLSIDX::text), '^^') 
            , '||', IFNULL(TRIM(IVSLDSIX::text), '^^') 
            , '||', IFNULL(TRIM(IVSLRNIX::text), '^^') 
            , '||', IFNULL(TRIM(IVINUSIX::text), '^^') 
            , '||', IFNULL(TRIM(IVINSVIX::text), '^^') 
            , '||', IFNULL(TRIM(IVDMGIDX::text), '^^') 
            , '||', IFNULL(TRIM(IVVARIDX::text), '^^') 
            , '||', IFNULL(TRIM(DPSHPIDX::text), '^^') 
            , '||', IFNULL(TRIM(PURPVIDX::text), '^^') 
            , '||', IFNULL(TRIM(UPPVIDX::text), '^^') 
            , '||', IFNULL(TRIM(IVRETIDX::text), '^^') 
            , '||', IFNULL(TRIM(ASMVRIDX::text), '^^') 
            , '||', IFNULL(TRIM(ITMCLSCD::text), '^^') 
            , '||', IFNULL(TRIM(ITMTRKOP::text), '^^') 
            , '||', IFNULL(TRIM(LOTTYPE::text), '^^') 
            , '||', IFNULL(TRIM(KPERHIST::text), '^^') 
            , '||', IFNULL(TRIM(KPTRXHST::text), '^^') 
            , '||', IFNULL(TRIM(KPCALHST::text), '^^') 
            , '||', IFNULL(TRIM(KPDSTHST::text), '^^') 
            , '||', IFNULL(TRIM(ALWBKORD::text), '^^') 
            , '||', IFNULL(TRIM(VCTNMTHD::text), '^^') 
            , '||', IFNULL(TRIM(UOMSCHDL::text), '^^') 
            , '||', IFNULL(TRIM(ALTITEM1::text), '^^') 
            , '||', IFNULL(TRIM(ALTITEM2::text), '^^') 
            , '||', IFNULL(TRIM(USCATVLS_1::text), '^^') 
            , '||', IFNULL(TRIM(USCATVLS_2::text), '^^') 
            , '||', IFNULL(TRIM(USCATVLS_3::text), '^^') 
            , '||', IFNULL(TRIM(USCATVLS_4::text), '^^') 
            , '||', IFNULL(TRIM(USCATVLS_5::text), '^^') 
            , '||', IFNULL(TRIM(USCATVLS_6::text), '^^') 
            , '||', IFNULL(TRIM(MSTRCDTY::text), '^^') 
            , '||', IFNULL(TRIM(MODIFDT::text), '^^') 
            , '||', IFNULL(TRIM(CREATDDT::text), '^^') 
            , '||', IFNULL(TRIM(WRNTYDYS::text), '^^') 
            , '||', IFNULL(TRIM(PRCLEVEL::text), '^^') 
            , '||', IFNULL(TRIM(LOCNCODE::text), '^^') 
            , '||', IFNULL(TRIM(PINFLIDX::text), '^^') 
            , '||', IFNULL(TRIM(PURMCIDX::text), '^^') 
            , '||', IFNULL(TRIM(IVINFIDX::text), '^^') 
            , '||', IFNULL(TRIM(INVMCIDX::text), '^^') 
            , '||', IFNULL(TRIM(CGSINFLX::text), '^^') 
            , '||', IFNULL(TRIM(CGSMCIDX::text), '^^') 
            , '||', IFNULL(TRIM(ITEMCODE::text), '^^') 
            , '||', IFNULL(TRIM(TCC::text), '^^') 
            , '||', IFNULL(TRIM(PRICEGROUP::text), '^^') 
            , '||', IFNULL(TRIM(PRICMTHD::text), '^^') 
            , '||', IFNULL(TRIM(PRCHSUOM::text), '^^') 
            , '||', IFNULL(TRIM(SELNGUOM::text), '^^') 
            , '||', IFNULL(TRIM(KTACCTSR::text), '^^') 
            , '||', IFNULL(TRIM(LASTGENSN::text), '^^') 
            , '||', IFNULL(TRIM(ABCCODE::text), '^^') 
            , '||', IFNULL(TRIM(REVALUE_INVENTORY::text), '^^') 
            , '||', IFNULL(TRIM(TOLERANCE_PERCENTAGE::text), '^^') 
            , '||', IFNULL(TRIM(PURCHASE_ITEM_TAX_SCHEDU::text), '^^') 
            , '||', IFNULL(TRIM(PURCHASE_TAX_OPTIONS::text), '^^') 
            , '||', IFNULL(TRIM(ITMPLNNNGTYP::text), '^^') 
            , '||', IFNULL(TRIM(STTSTCLVLPRCNTG::text), '^^') 
            , '||', IFNULL(TRIM(CNTRYORGN::text), '^^') 
            , '||', IFNULL(TRIM(INACTIVE::text), '^^') 
            , '||', IFNULL(TRIM(MINSHELF1::text), '^^') 
            , '||', IFNULL(TRIM(MINSHELF2::text), '^^') 
            , '||', IFNULL(TRIM(INCLUDEINDP::text), '^^') 
            , '||', IFNULL(TRIM(DEX_ROW_ID::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
