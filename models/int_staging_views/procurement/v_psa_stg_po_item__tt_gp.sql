---- SRC LAYER ----
WITH
SRC_pitm           as ( SELECT ADDRESS1, ADDRESS2, ADDRESS3, ADDRSOURCE, ADRSCODE, BACKOUTTRADEDISCTAX, BCKTXAMT, BRKFLD1, BSIVCTTL, CAPITAL_ITEM, CCODE, CHANGE_ORDER_FLAG, CITY, CMPNYNAM, COMMNTID, CONTACT, COSTCATID, COSTCODE, COSTTYPE, COUNTRY, CURNCYID, CURRNIDX, DECPLCUR, DECPLQTY, DENXRATE, DEX_ROW_ID, DOCTYPE, EXTDCOST, FAX, FLAGS, FREEONBOARD, FSTRCPTDT, INVINDX, ITEMDESC, ITEMNMBR, ITMTRKOP, JOBNUMBR, LANDED_COST_GROUP_ID, LINENUMBER, LINEORIGIN, LOCNCODE, LSTRCPTDT, NONINVEN, OBTAXAMT, ODECPLCU, OPOSTSUB, ORD, OREXTCST, ORIGBACKOUTTRADEDISCTAX, ORIGPRMDATE, ORTAXAMT, ORUNTCST, PHONE1, PHONE2, PHONE3, PLNNDSPPLID, POLNEARY_1, POLNEARY_2, POLNEARY_3, POLNEARY_4, POLNEARY_5, POLNEARY_6, POLNEARY_7, POLNEARY_8, POLNEARY_9, POLNESTA, PONUMBER, POTYPE, PO_LINE_STATUS_ORIG, PRMDATE, PRMSHPDTE, PRODUCT_INDICATOR, PROJNUM, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PURCHASE_ITEM_TAX_SCHEDU, PURCHASE_IV_ITEM_TAXABLE, PURCHASE_SITE_TAX_SCHEDU, PURCHSITETXSCHSRC, QTYCANCE, QTYCMTBASE, QTYORDER, QTYUNCMTBASE, QTY_CANCELED_ORIG, RATECALC, RELEASE, RELEASEBYDATE, RELEASED_DATE, REQDATE, REQSTDBY, SHIPMTHD, SOURCE_DOCUMENT_LINE_NUM, SOURCE_DOCUMENT_NUMBER, STATE, TAXAMNT, UMQTYINB, UNITCOST, UOFM, VCTNMTHD, VENDORID, VNDITDSC, VNDITNUM, XCHGRATE, ZIPCODE FROM {{ source('tt_gpd', 'dbo_pop10110') }} as SRC  ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_po             as ( SELECT CMPANYID, PONUMBER FROM {{ source('tt_gpd', 'dbo_pop10100') }} as SRC 
                        qualify 1 = row_number()over (partition by ponumber order by psa_load_dts desc) )

/*
SRC_pitm           as ( SELECT * FROM tt_gpd.dbo_pop10110 )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_po             as ( SELECT * FROM tt_gpd.dbo_pop10100 )
*/
---- LOGIC LAYER ----

, LOGIC_pitm as (
    SELECT
        PONUMBER                                                     as                                       PO_HEADER_BK
      , CONCAT_WS('||', COALESCE(PONUMBER, ''), COALESCE(ORD::TEXT, '')) as                                         PO_ITEM_BK
      , PONUMBER
      , ORD
      , POLNESTA
      , POTYPE
      , ITEMNMBR
      , ITEMDESC
      , VENDORID
      , VNDITNUM
      , VNDITDSC
      , NONINVEN
      , LOCNCODE
      , UOFM
      , UMQTYINB
      , QTYORDER
      , QTYCANCE
      , QTYCMTBASE
      , QTYUNCMTBASE
      , UNITCOST
      , EXTDCOST
      , INVINDX
      , REQDATE
      , PRMDATE
      , PRMSHPDTE
      , REQSTDBY
      , COMMNTID
      , DOCTYPE
      , POLNEARY_1
      , POLNEARY_2
      , POLNEARY_3
      , POLNEARY_4
      , POLNEARY_5
      , POLNEARY_6
      , POLNEARY_7
      , POLNEARY_8
      , POLNEARY_9
      , DECPLCUR
      , DECPLQTY
      , ITMTRKOP
      , VCTNMTHD
      , BRKFLD1
      , PO_LINE_STATUS_ORIG
      , QTY_CANCELED_ORIG
      , OPOSTSUB
      , JOBNUMBR
      , COSTCODE
      , COSTTYPE
      , CURNCYID
      , CURRNIDX
      , XCHGRATE
      , RATECALC
      , DENXRATE
      , ORUNTCST
      , OREXTCST
      , LINEORIGIN
      , FREEONBOARD
      , ODECPLCU
      , CAPITAL_ITEM
      , PRODUCT_INDICATOR
      , SOURCE_DOCUMENT_NUMBER
      , SOURCE_DOCUMENT_LINE_NUM
      , RELEASEBYDATE
      , RELEASED_DATE
      , CHANGE_ORDER_FLAG
      , PURCHASE_IV_ITEM_TAXABLE
      , PURCHASE_ITEM_TAX_SCHEDU
      , PURCHASE_SITE_TAX_SCHEDU
      , PURCHSITETXSCHSRC
      , BSIVCTTL
      , TAXAMNT
      , ORTAXAMT
      , BCKTXAMT
      , OBTAXAMT
      , LANDED_COST_GROUP_ID
      , PLNNDSPPLID
      , SHIPMTHD
      , BACKOUTTRADEDISCTAX
      , ORIGBACKOUTTRADEDISCTAX
      , LINENUMBER
      , ORIGPRMDATE
      , FSTRCPTDT
      , LSTRCPTDT
      , RELEASE
      , ADRSCODE
      , CMPNYNAM
      , CONTACT
      , ADDRESS1
      , ADDRESS2
      , ADDRESS3
      , CITY
      , STATE
      , ZIPCODE
      , CCODE
      , COUNTRY
      , PHONE1
      , PHONE2
      , PHONE3
      , FAX
      , ADDRSOURCE
      , FLAGS
      , PROJNUM
      , COSTCATID
      , DEX_ROW_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
    FROM SRC_pitm
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)

, LOGIC_po as (
    SELECT
        PONUMBER                                                     as                                        PO_PONUMBER
      , CMPANYID
    FROM SRC_po
)
---- RENAME LAYER ----

, RENAME_pitm as (
    SELECT
        PO_HEADER_BK
      , PO_ITEM_BK
      , PONUMBER
      , ORD
      , POLNESTA
      , POTYPE
      , ITEMNMBR
      , ITEMDESC
      , VENDORID
      , VNDITNUM
      , VNDITDSC
      , NONINVEN
      , LOCNCODE
      , UOFM
      , UMQTYINB
      , QTYORDER
      , QTYCANCE
      , QTYCMTBASE
      , QTYUNCMTBASE
      , UNITCOST
      , EXTDCOST
      , INVINDX
      , REQDATE
      , PRMDATE
      , PRMSHPDTE
      , REQSTDBY
      , COMMNTID
      , DOCTYPE
      , POLNEARY_1
      , POLNEARY_2
      , POLNEARY_3
      , POLNEARY_4
      , POLNEARY_5
      , POLNEARY_6
      , POLNEARY_7
      , POLNEARY_8
      , POLNEARY_9
      , DECPLCUR
      , DECPLQTY
      , ITMTRKOP
      , VCTNMTHD
      , BRKFLD1
      , PO_LINE_STATUS_ORIG
      , QTY_CANCELED_ORIG
      , OPOSTSUB
      , JOBNUMBR
      , COSTCODE
      , COSTTYPE
      , CURNCYID
      , CURRNIDX
      , XCHGRATE
      , RATECALC
      , DENXRATE
      , ORUNTCST
      , OREXTCST
      , LINEORIGIN
      , FREEONBOARD
      , ODECPLCU
      , CAPITAL_ITEM
      , PRODUCT_INDICATOR
      , SOURCE_DOCUMENT_NUMBER
      , SOURCE_DOCUMENT_LINE_NUM
      , RELEASEBYDATE
      , RELEASED_DATE
      , CHANGE_ORDER_FLAG
      , PURCHASE_IV_ITEM_TAXABLE
      , PURCHASE_ITEM_TAX_SCHEDU
      , PURCHASE_SITE_TAX_SCHEDU
      , PURCHSITETXSCHSRC
      , BSIVCTTL
      , TAXAMNT
      , ORTAXAMT
      , BCKTXAMT
      , OBTAXAMT
      , LANDED_COST_GROUP_ID
      , PLNNDSPPLID
      , SHIPMTHD
      , BACKOUTTRADEDISCTAX
      , ORIGBACKOUTTRADEDISCTAX
      , LINENUMBER
      , ORIGPRMDATE
      , FSTRCPTDT
      , LSTRCPTDT
      , RELEASE
      , ADRSCODE
      , CMPNYNAM
      , CONTACT
      , ADDRESS1
      , ADDRESS2
      , ADDRESS3
      , CITY
      , STATE
      , ZIPCODE
      , CCODE
      , COUNTRY
      , PHONE1
      , PHONE2
      , PHONE3
      , FAX
      , ADDRSOURCE
      , FLAGS
      , PROJNUM
      , COSTCATID
      , DEX_ROW_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_pitm
)

, RENAME_po as (
    SELECT
        PO_PONUMBER
      , CMPANYID
    FROM LOGIC_po
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_pitm as (
    SELECT *
    FROM RENAME_pitm
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USOHMA.MSSQL.GPPRD.DBO_POP10110'
)

, FILTER_po as (
    SELECT *
    FROM RENAME_po
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_pitm
    INNER JOIN FILTER_a
        ON '1' = '1'
    LEFT JOIN FILTER_po
        ON FILTER_pitm.PONUMBER = PO_PONUMBER
)

---- FINAL LAYER ----
SELECT
          PO_HEADER_BK
        , PO_ITEM_BK
        , PONUMBER
        , ORD
        , POLNESTA
        , POTYPE
        , ITEMNMBR
        , ITEMDESC
        , VENDORID
        , VNDITNUM
        , VNDITDSC
        , NONINVEN
        , LOCNCODE
        , UOFM
        , UMQTYINB
        , QTYORDER
        , QTYCANCE
        , QTYCMTBASE
        , QTYUNCMTBASE
        , UNITCOST
        , EXTDCOST
        , INVINDX
        , REQDATE
        , PRMDATE
        , PRMSHPDTE
        , REQSTDBY
        , COMMNTID
        , DOCTYPE
        , POLNEARY_1
        , POLNEARY_2
        , POLNEARY_3
        , POLNEARY_4
        , POLNEARY_5
        , POLNEARY_6
        , POLNEARY_7
        , POLNEARY_8
        , POLNEARY_9
        , DECPLCUR
        , DECPLQTY
        , ITMTRKOP
        , VCTNMTHD
        , BRKFLD1
        , PO_LINE_STATUS_ORIG
        , QTY_CANCELED_ORIG
        , OPOSTSUB
        , JOBNUMBR
        , COSTCODE
        , COSTTYPE
        , CURNCYID
        , CURRNIDX
        , XCHGRATE
        , RATECALC
        , DENXRATE
        , ORUNTCST
        , OREXTCST
        , LINEORIGIN
        , FREEONBOARD
        , ODECPLCU
        , CAPITAL_ITEM
        , PRODUCT_INDICATOR
        , SOURCE_DOCUMENT_NUMBER
        , SOURCE_DOCUMENT_LINE_NUM
        , RELEASEBYDATE
        , RELEASED_DATE
        , CHANGE_ORDER_FLAG
        , PURCHASE_IV_ITEM_TAXABLE
        , PURCHASE_ITEM_TAX_SCHEDU
        , PURCHASE_SITE_TAX_SCHEDU
        , PURCHSITETXSCHSRC
        , BSIVCTTL
        , TAXAMNT
        , ORTAXAMT
        , BCKTXAMT
        , OBTAXAMT
        , LANDED_COST_GROUP_ID
        , PLNNDSPPLID
        , SHIPMTHD
        , BACKOUTTRADEDISCTAX
        , ORIGBACKOUTTRADEDISCTAX
        , LINENUMBER
        , ORIGPRMDATE
        , FSTRCPTDT
        , LSTRCPTDT
        , RELEASE
        , ADRSCODE
        , CMPNYNAM
        , CONTACT
        , ADDRESS1
        , ADDRESS2
        , ADDRESS3
        , CITY
        , STATE
        , ZIPCODE
        , CCODE
        , COUNTRY
        , PHONE1
        , PHONE2
        , PHONE3
        , FAX
        , ADDRSOURCE
        , FLAGS
        , PROJNUM
        , COSTCATID
        , DEX_ROW_ID
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PONUMBER as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ORD as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PONUMBER as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_HEADER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VENDORID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEMNMBR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
        ))) as PURCHASING_RECORD_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
        ))) as PURCHASING_ORG_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CMPANYID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LEGAL_ENTITY_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PONUMBER as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ORD as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(VENDORID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ITEMNMBR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CMPANYID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
        ))) as LNK_PO_ITEM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(POLNESTA::text), '^^') 
            , '||', IFNULL(TRIM(POTYPE::text), '^^') 
            , '||', IFNULL(TRIM(ITEMNMBR::text), '^^') 
            , '||', IFNULL(TRIM(ITEMDESC::text), '^^') 
            , '||', IFNULL(TRIM(VENDORID::text), '^^') 
            , '||', IFNULL(TRIM(VNDITNUM::text), '^^') 
            , '||', IFNULL(TRIM(VNDITDSC::text), '^^') 
            , '||', IFNULL(TRIM(NONINVEN::text), '^^') 
            , '||', IFNULL(TRIM(LOCNCODE::text), '^^') 
            , '||', IFNULL(TRIM(UOFM::text), '^^') 
            , '||', IFNULL(TRIM(UMQTYINB::text), '^^') 
            , '||', IFNULL(TRIM(QTYORDER::text), '^^') 
            , '||', IFNULL(TRIM(QTYCANCE::text), '^^') 
            , '||', IFNULL(TRIM(QTYCMTBASE::text), '^^') 
            , '||', IFNULL(TRIM(QTYUNCMTBASE::text), '^^') 
            , '||', IFNULL(TRIM(UNITCOST::text), '^^') 
            , '||', IFNULL(TRIM(EXTDCOST::text), '^^') 
            , '||', IFNULL(TRIM(INVINDX::text), '^^') 
            , '||', IFNULL(TRIM(REQDATE::text), '^^') 
            , '||', IFNULL(TRIM(PRMDATE::text), '^^') 
            , '||', IFNULL(TRIM(PRMSHPDTE::text), '^^') 
            , '||', IFNULL(TRIM(REQSTDBY::text), '^^') 
            , '||', IFNULL(TRIM(COMMNTID::text), '^^') 
            , '||', IFNULL(TRIM(DOCTYPE::text), '^^') 
            , '||', IFNULL(TRIM(POLNEARY_1::text), '^^') 
            , '||', IFNULL(TRIM(POLNEARY_2::text), '^^') 
            , '||', IFNULL(TRIM(POLNEARY_3::text), '^^') 
            , '||', IFNULL(TRIM(POLNEARY_4::text), '^^') 
            , '||', IFNULL(TRIM(POLNEARY_5::text), '^^') 
            , '||', IFNULL(TRIM(POLNEARY_6::text), '^^') 
            , '||', IFNULL(TRIM(POLNEARY_7::text), '^^') 
            , '||', IFNULL(TRIM(POLNEARY_8::text), '^^') 
            , '||', IFNULL(TRIM(POLNEARY_9::text), '^^') 
            , '||', IFNULL(TRIM(DECPLCUR::text), '^^') 
            , '||', IFNULL(TRIM(DECPLQTY::text), '^^') 
            , '||', IFNULL(TRIM(ITMTRKOP::text), '^^') 
            , '||', IFNULL(TRIM(VCTNMTHD::text), '^^') 
            , '||', IFNULL(TRIM(BRKFLD1::text), '^^') 
            , '||', IFNULL(TRIM(PO_LINE_STATUS_ORIG::text), '^^') 
            , '||', IFNULL(TRIM(QTY_CANCELED_ORIG::text), '^^') 
            , '||', IFNULL(TRIM(OPOSTSUB::text), '^^') 
            , '||', IFNULL(TRIM(JOBNUMBR::text), '^^') 
            , '||', IFNULL(TRIM(COSTCODE::text), '^^') 
            , '||', IFNULL(TRIM(COSTTYPE::text), '^^') 
            , '||', IFNULL(TRIM(CURNCYID::text), '^^') 
            , '||', IFNULL(TRIM(CURRNIDX::text), '^^') 
            , '||', IFNULL(TRIM(XCHGRATE::text), '^^') 
            , '||', IFNULL(TRIM(RATECALC::text), '^^') 
            , '||', IFNULL(TRIM(DENXRATE::text), '^^') 
            , '||', IFNULL(TRIM(ORUNTCST::text), '^^') 
            , '||', IFNULL(TRIM(OREXTCST::text), '^^') 
            , '||', IFNULL(TRIM(LINEORIGIN::text), '^^') 
            , '||', IFNULL(TRIM(FREEONBOARD::text), '^^') 
            , '||', IFNULL(TRIM(ODECPLCU::text), '^^') 
            , '||', IFNULL(TRIM(CAPITAL_ITEM::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_INDICATOR::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_DOCUMENT_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_DOCUMENT_LINE_NUM::text), '^^') 
            , '||', IFNULL(TRIM(RELEASEBYDATE::text), '^^') 
            , '||', IFNULL(TRIM(RELEASED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CHANGE_ORDER_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PURCHASE_IV_ITEM_TAXABLE::text), '^^') 
            , '||', IFNULL(TRIM(PURCHASE_ITEM_TAX_SCHEDU::text), '^^') 
            , '||', IFNULL(TRIM(PURCHASE_SITE_TAX_SCHEDU::text), '^^') 
            , '||', IFNULL(TRIM(PURCHSITETXSCHSRC::text), '^^') 
            , '||', IFNULL(TRIM(BSIVCTTL::text), '^^') 
            , '||', IFNULL(TRIM(TAXAMNT::text), '^^') 
            , '||', IFNULL(TRIM(ORTAXAMT::text), '^^') 
            , '||', IFNULL(TRIM(BCKTXAMT::text), '^^') 
            , '||', IFNULL(TRIM(OBTAXAMT::text), '^^') 
            , '||', IFNULL(TRIM(LANDED_COST_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(PLNNDSPPLID::text), '^^') 
            , '||', IFNULL(TRIM(SHIPMTHD::text), '^^') 
            , '||', IFNULL(TRIM(BACKOUTTRADEDISCTAX::text), '^^') 
            , '||', IFNULL(TRIM(ORIGBACKOUTTRADEDISCTAX::text), '^^') 
            , '||', IFNULL(TRIM(LINENUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ORIGPRMDATE::text), '^^') 
            , '||', IFNULL(TRIM(FSTRCPTDT::text), '^^') 
            , '||', IFNULL(TRIM(LSTRCPTDT::text), '^^') 
            , '||', IFNULL(TRIM(RELEASE::text), '^^') 
            , '||', IFNULL(TRIM(ADRSCODE::text), '^^') 
            , '||', IFNULL(TRIM(CMPNYNAM::text), '^^') 
            , '||', IFNULL(TRIM(CONTACT::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS1::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS2::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS3::text), '^^') 
            , '||', IFNULL(TRIM(CITY::text), '^^') 
            , '||', IFNULL(TRIM(STATE::text), '^^') 
            , '||', IFNULL(TRIM(ZIPCODE::text), '^^') 
            , '||', IFNULL(TRIM(CCODE::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(PHONE1::text), '^^') 
            , '||', IFNULL(TRIM(PHONE2::text), '^^') 
            , '||', IFNULL(TRIM(PHONE3::text), '^^') 
            , '||', IFNULL(TRIM(FAX::text), '^^') 
            , '||', IFNULL(TRIM(ADDRSOURCE::text), '^^') 
            , '||', IFNULL(TRIM(FLAGS::text), '^^') 
            , '||', IFNULL(TRIM(PROJNUM::text), '^^') 
            , '||', IFNULL(TRIM(COSTCATID::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
