---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('tt_gpd', 'dbo_iv40400') }} as SRC 
                        /*The following qualify clause is required to pick the first entered record to resolve an issue with the great plains tables in PSA where duplicate records are being loaded for every table every day */
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY ITMCLSCD ORDER BY PSA_LOAD_DTS) ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM tt_gpd.dbo_iv40400 )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        ITMCLSCD
      , ITMCLSDC
      , DEFLTCLS
      , NOTEINDX
      , ITEMTYPE
      , ITMTRKOP
      , LOTTYPE
      , KPERHIST
      , KPTRXHST
      , KPCALHST
      , KPDSTHST
      , ALWBKORD
      , ITMGEDSC
      , TAXOPTNS
      , ITMTSHID
      , PURCHASE_TAX_OPTIONS
      , PURCHASE_ITEM_TAX_SCHEDU
      , UOMSCHDL
      , VCTNMTHD
      , USCATVLS_1
      , USCATVLS_2
      , USCATVLS_3
      , USCATVLS_4
      , USCATVLS_5
      , USCATVLS_6
      , DECPLQTY
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
      , PRCLEVEL
      , PRICEGROUP
      , PRICMTHD
      , TCC
      , REVALUE_INVENTORY
      , TOLERANCE_PERCENTAGE
      , CNTRYORGN
      , STTSTCLVLPRCNTG
      , INCLUDEINDP
      , DEX_ROW_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC',PSA_LOAD_DTS)                         as                                           LOAD_DTS
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
        ITMCLSCD
      , ITMCLSDC
      , DEFLTCLS
      , NOTEINDX
      , ITEMTYPE
      , ITMTRKOP
      , LOTTYPE
      , KPERHIST
      , KPTRXHST
      , KPCALHST
      , KPDSTHST
      , ALWBKORD
      , ITMGEDSC
      , TAXOPTNS
      , ITMTSHID
      , PURCHASE_TAX_OPTIONS
      , PURCHASE_ITEM_TAX_SCHEDU
      , UOMSCHDL
      , VCTNMTHD
      , USCATVLS_1
      , USCATVLS_2
      , USCATVLS_3
      , USCATVLS_4
      , USCATVLS_5
      , USCATVLS_6
      , DECPLQTY
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
      , PRCLEVEL
      , PRICEGROUP
      , PRICMTHD
      , TCC
      , REVALUE_INVENTORY
      , TOLERANCE_PERCENTAGE
      , CNTRYORGN
      , STTSTCLVLPRCNTG
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
    WHERE rec_src = 'USOHMA.MSSQL.GPPRD.DBO_IV40400'
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
          coalesce(nullif(trim(ITMCLSCD),''),'-1')                     as ITEM_CLASS_BK
        , ITMCLSCD
        , ITMCLSDC
        , DEFLTCLS
        , NOTEINDX
        , ITEMTYPE
        , ITMTRKOP
        , LOTTYPE
        , KPERHIST
        , KPTRXHST
        , KPCALHST
        , KPDSTHST
        , ALWBKORD
        , ITMGEDSC
        , TAXOPTNS
        , ITMTSHID
        , PURCHASE_TAX_OPTIONS
        , PURCHASE_ITEM_TAX_SCHEDU
        , UOMSCHDL
        , VCTNMTHD
        , USCATVLS_1
        , USCATVLS_2
        , USCATVLS_3
        , USCATVLS_4
        , USCATVLS_5
        , USCATVLS_6
        , DECPLQTY
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
        , PRCLEVEL
        , PRICEGROUP
        , PRICMTHD
        , TCC
        , REVALUE_INVENTORY
        , TOLERANCE_PERCENTAGE
        , CNTRYORGN
        , STTSTCLVLPRCNTG
        , INCLUDEINDP
        , DEX_ROW_ID
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ITMCLSDC::text), '^^') 
            , '||', IFNULL(TRIM(DEFLTCLS::text), '^^') 
            , '||', IFNULL(TRIM(NOTEINDX::text), '^^') 
            , '||', IFNULL(TRIM(ITEMTYPE::text), '^^') 
            , '||', IFNULL(TRIM(ITMTRKOP::text), '^^') 
            , '||', IFNULL(TRIM(LOTTYPE::text), '^^') 
            , '||', IFNULL(TRIM(KPERHIST::text), '^^') 
            , '||', IFNULL(TRIM(KPTRXHST::text), '^^') 
            , '||', IFNULL(TRIM(KPCALHST::text), '^^') 
            , '||', IFNULL(TRIM(KPDSTHST::text), '^^') 
            , '||', IFNULL(TRIM(ALWBKORD::text), '^^') 
            , '||', IFNULL(TRIM(ITMGEDSC::text), '^^') 
            , '||', IFNULL(TRIM(TAXOPTNS::text), '^^') 
            , '||', IFNULL(TRIM(ITMTSHID::text), '^^') 
            , '||', IFNULL(TRIM(PURCHASE_TAX_OPTIONS::text), '^^') 
            , '||', IFNULL(TRIM(PURCHASE_ITEM_TAX_SCHEDU::text), '^^') 
            , '||', IFNULL(TRIM(UOMSCHDL::text), '^^') 
            , '||', IFNULL(TRIM(VCTNMTHD::text), '^^') 
            , '||', IFNULL(TRIM(USCATVLS_1::text), '^^') 
            , '||', IFNULL(TRIM(USCATVLS_2::text), '^^') 
            , '||', IFNULL(TRIM(USCATVLS_3::text), '^^') 
            , '||', IFNULL(TRIM(USCATVLS_4::text), '^^') 
            , '||', IFNULL(TRIM(USCATVLS_5::text), '^^') 
            , '||', IFNULL(TRIM(USCATVLS_6::text), '^^') 
            , '||', IFNULL(TRIM(DECPLQTY::text), '^^') 
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
            , '||', IFNULL(TRIM(PRCLEVEL::text), '^^') 
            , '||', IFNULL(TRIM(PRICEGROUP::text), '^^') 
            , '||', IFNULL(TRIM(PRICMTHD::text), '^^') 
            , '||', IFNULL(TRIM(TCC::text), '^^') 
            , '||', IFNULL(TRIM(REVALUE_INVENTORY::text), '^^') 
            , '||', IFNULL(TRIM(TOLERANCE_PERCENTAGE::text), '^^') 
            , '||', IFNULL(TRIM(CNTRYORGN::text), '^^') 
            , '||', IFNULL(TRIM(STTSTCLVLPRCNTG::text), '^^') 
            , '||', IFNULL(TRIM(INCLUDEINDP::text), '^^') 
            , '||', IFNULL(TRIM(DEX_ROW_ID::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
