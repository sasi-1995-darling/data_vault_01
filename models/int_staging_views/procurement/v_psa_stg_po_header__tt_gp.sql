---- SRC LAYER ----
WITH
SRC_ph             as ( SELECT ADDRESS1, ADDRESS2, ADDRESS3, ALLOWSOCMTS, BACKOUTFREIGHTTAXAMT, BACKOUTMISCTAXAMT, BACKOUTTRADEDISCTAX, BCKTXAMT, BLNKTLINEEXTQTYSUM, BSIVCTTL, BUYERID, CANCSUB, CBVAT, CCODE, CHANGE_ORDER_FLAG, CITY, CMPANYID, CMPNYNAM, CNTRLBLKTBY, COMMNTID, CONFIRM1, CONTACT, CONTENDDTE, COUNTRY, CREATDDT, CURNCYID, CURRNIDX, CUSTNMBR, DENXRATE, DEX_ROW_ID, DISAMTAV, DISCDATE, DISGRPER, DOCDATE, DSCDLRAM, DSCPCTAM, DUEDATE, DUEGRPER, EXCHDATE, EXGTBLID, FAX, FLAGS, FRTAMNT, FRTSCHID, FRTTXAMT, HOLD, HOLDREMOVEBY, HOLDREMOVEDATE, LSTEDTDT, LSTPRTDT, MCTRXSTT, MINORDER, MODIFDT, MSCCHAMT, MSCSCHID, MSCTXAMT, OBTAXAMT, ODISAMTAV, OMISCAMT, ONHOLDBY, ONHOLDDATE, ONORDAMT, ORDDLRAT, OREMSUBT, ORFRTAMT, ORFRTTAX, ORIGBACKOUTFREIGHTTAXAMT, ORIGBACKOUTMISCTAXAMT, ORIGBACKOUTTRADEDISCTAX, ORIGINATING_CANCELED_SUB, ORMSCTAX, ORORDAMT, ORSUBTOT, ORTAXAMT, ORTDISAM, PHONE1, PHONE2, PHONE3, PONOTIDS_1, PONOTIDS_10, PONOTIDS_11, PONOTIDS_12, PONOTIDS_13, PONOTIDS_14, PONOTIDS_15, PONOTIDS_2, PONOTIDS_3, PONOTIDS_4, PONOTIDS_5, PONOTIDS_6, PONOTIDS_7, PONOTIDS_8, PONOTIDS_9, PONUMBER, POPCONTNUM, POSTATUS, POTYPE, PO_FIELD_CHANGES, PO_STATUS_ORIG, PRBTADCD, PRMDATE, PRMSHPDTE, PRSTADCD, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PURCHADDRESS1, PURCHADDRESS2, PURCHADDRESS3, PURCHASE_FREIGHT_TAXABLE, PURCHASE_MISC_TAXABLE, PURCHCCODE, PURCHCITY, PURCHCMPNYNAM, PURCHCONTACT, PURCHCOUNTRY, PURCHFAX, PURCHPHONE1, PURCHPHONE2, PURCHPHONE3, PURCHSTATE, PURCHZIPCODE, PYMTRMID, RATECALC, RATETPID, REMSUBTO, REQDATE, REQTNDT, REVISION_NUMBER, SHIPMTHD, STATE, STATGRP, SUBTOTAL, TAXAMNT, TAXSCHID, TIME1, TIMESPRT, TRDISAMT, TRDPCTPR, TXENGCLD, TXRGNNUM, TXSCHSRC, USER2ENT, VADCDPAD, VENDNAME, VENDORID, XCHGRATE, ZIPCODE FROM {{ source('tt_gpd', 'dbo_pop10100') }} as SRC  ),
SRC_A              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_ph             as ( SELECT * FROM tt_gpd.dbo_pop10100 )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_ph as (
    SELECT
        PONUMBER                                                     as                                       PO_HEADER_BK
      , PONUMBER
      , POSTATUS
      , STATGRP
      , POTYPE
      , USER2ENT
      , CONFIRM1
      , DOCDATE
      , LSTEDTDT
      , LSTPRTDT
      , PRMDATE
      , PRMSHPDTE
      , REQDATE
      , REQTNDT
      , SHIPMTHD
      , TXRGNNUM
      , REMSUBTO
      , SUBTOTAL
      , TRDISAMT
      , FRTAMNT
      , MSCCHAMT
      , TAXAMNT
      , VENDORID
      , VENDNAME
      , MINORDER
      , VADCDPAD
      , CMPANYID
      , PRBTADCD
      , PRSTADCD
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
      , PYMTRMID
      , DSCDLRAM
      , DSCPCTAM
      , DISAMTAV
      , DISCDATE
      , DUEDATE
      , TRDPCTPR
      , CUSTNMBR
      , TIMESPRT
      , CREATDDT
      , MODIFDT
      , PONOTIDS_1
      , PONOTIDS_2
      , PONOTIDS_3
      , PONOTIDS_4
      , PONOTIDS_5
      , PONOTIDS_6
      , PONOTIDS_7
      , PONOTIDS_8
      , PONOTIDS_9
      , PONOTIDS_10
      , PONOTIDS_11
      , PONOTIDS_12
      , PONOTIDS_13
      , PONOTIDS_14
      , PONOTIDS_15
      , COMMNTID
      , CANCSUB
      , CURNCYID
      , CURRNIDX
      , RATETPID
      , EXGTBLID
      , XCHGRATE
      , EXCHDATE
      , TIME1
      , RATECALC
      , DENXRATE
      , MCTRXSTT
      , OREMSUBT
      , ORSUBTOT
      , ORIGINATING_CANCELED_SUB
      , ORTDISAM
      , ORFRTAMT
      , OMISCAMT
      , ORTAXAMT
      , ORDDLRAT
      , ODISAMTAV
      , BUYERID
      , ONORDAMT
      , ORORDAMT
      , HOLD
      , ONHOLDDATE
      , ONHOLDBY
      , HOLDREMOVEDATE
      , HOLDREMOVEBY
      , ALLOWSOCMTS
      , DISGRPER
      , DUEGRPER
      , REVISION_NUMBER
      , CHANGE_ORDER_FLAG
      , PO_FIELD_CHANGES
      , PO_STATUS_ORIG
      , TAXSCHID
      , TXSCHSRC
      , TXENGCLD
      , BSIVCTTL
      , PURCHASE_FREIGHT_TAXABLE
      , PURCHASE_MISC_TAXABLE
      , FRTSCHID
      , MSCSCHID
      , FRTTXAMT
      , ORFRTTAX
      , MSCTXAMT
      , ORMSCTAX
      , BCKTXAMT
      , OBTAXAMT
      , BACKOUTFREIGHTTAXAMT
      , ORIGBACKOUTFREIGHTTAXAMT
      , BACKOUTMISCTAXAMT
      , ORIGBACKOUTMISCTAXAMT
      , FLAGS
      , BACKOUTTRADEDISCTAX
      , ORIGBACKOUTTRADEDISCTAX
      , POPCONTNUM
      , CONTENDDTE
      , CNTRLBLKTBY
      , PURCHCMPNYNAM
      , PURCHCONTACT
      , PURCHADDRESS1
      , PURCHADDRESS2
      , PURCHADDRESS3
      , PURCHCITY
      , PURCHSTATE
      , PURCHZIPCODE
      , PURCHCCODE
      , PURCHCOUNTRY
      , PURCHPHONE1
      , PURCHPHONE2
      , PURCHPHONE3
      , PURCHFAX
      , BLNKTLINEEXTQTYSUM
      , CBVAT
      , DEX_ROW_ID
      , CMPANYID::TEXT                                               as                                    LEGAL_ENTITY_BK
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
    FROM SRC_ph
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_ph as (
    SELECT
        PO_HEADER_BK
      , PONUMBER
      , POSTATUS
      , STATGRP
      , POTYPE
      , USER2ENT
      , CONFIRM1
      , DOCDATE
      , LSTEDTDT
      , LSTPRTDT
      , PRMDATE
      , PRMSHPDTE
      , REQDATE
      , REQTNDT
      , SHIPMTHD
      , TXRGNNUM
      , REMSUBTO
      , SUBTOTAL
      , TRDISAMT
      , FRTAMNT
      , MSCCHAMT
      , TAXAMNT
      , VENDORID
      , VENDNAME
      , MINORDER
      , VADCDPAD
      , CMPANYID
      , PRBTADCD
      , PRSTADCD
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
      , PYMTRMID
      , DSCDLRAM
      , DSCPCTAM
      , DISAMTAV
      , DISCDATE
      , DUEDATE
      , TRDPCTPR
      , CUSTNMBR
      , TIMESPRT
      , CREATDDT
      , MODIFDT
      , PONOTIDS_1
      , PONOTIDS_2
      , PONOTIDS_3
      , PONOTIDS_4
      , PONOTIDS_5
      , PONOTIDS_6
      , PONOTIDS_7
      , PONOTIDS_8
      , PONOTIDS_9
      , PONOTIDS_10
      , PONOTIDS_11
      , PONOTIDS_12
      , PONOTIDS_13
      , PONOTIDS_14
      , PONOTIDS_15
      , COMMNTID
      , CANCSUB
      , CURNCYID
      , CURRNIDX
      , RATETPID
      , EXGTBLID
      , XCHGRATE
      , EXCHDATE
      , TIME1
      , RATECALC
      , DENXRATE
      , MCTRXSTT
      , OREMSUBT
      , ORSUBTOT
      , ORIGINATING_CANCELED_SUB
      , ORTDISAM
      , ORFRTAMT
      , OMISCAMT
      , ORTAXAMT
      , ORDDLRAT
      , ODISAMTAV
      , BUYERID
      , ONORDAMT
      , ORORDAMT
      , HOLD
      , ONHOLDDATE
      , ONHOLDBY
      , HOLDREMOVEDATE
      , HOLDREMOVEBY
      , ALLOWSOCMTS
      , DISGRPER
      , DUEGRPER
      , REVISION_NUMBER
      , CHANGE_ORDER_FLAG
      , PO_FIELD_CHANGES
      , PO_STATUS_ORIG
      , TAXSCHID
      , TXSCHSRC
      , TXENGCLD
      , BSIVCTTL
      , PURCHASE_FREIGHT_TAXABLE
      , PURCHASE_MISC_TAXABLE
      , FRTSCHID
      , MSCSCHID
      , FRTTXAMT
      , ORFRTTAX
      , MSCTXAMT
      , ORMSCTAX
      , BCKTXAMT
      , OBTAXAMT
      , BACKOUTFREIGHTTAXAMT
      , ORIGBACKOUTFREIGHTTAXAMT
      , BACKOUTMISCTAXAMT
      , ORIGBACKOUTMISCTAXAMT
      , FLAGS
      , BACKOUTTRADEDISCTAX
      , ORIGBACKOUTTRADEDISCTAX
      , POPCONTNUM
      , CONTENDDTE
      , CNTRLBLKTBY
      , PURCHCMPNYNAM
      , PURCHCONTACT
      , PURCHADDRESS1
      , PURCHADDRESS2
      , PURCHADDRESS3
      , PURCHCITY
      , PURCHSTATE
      , PURCHZIPCODE
      , PURCHCCODE
      , PURCHCOUNTRY
      , PURCHPHONE1
      , PURCHPHONE2
      , PURCHPHONE3
      , PURCHFAX
      , BLNKTLINEEXTQTYSUM
      , CBVAT
      , DEX_ROW_ID
      , LEGAL_ENTITY_BK
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_ph
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_ph as (
    SELECT *
    FROM RENAME_ph
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USOHMA.MSSQL.GPPRD.DBO_POP10100'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_ph
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          PO_HEADER_BK
        , PONUMBER
        , POSTATUS
        , STATGRP
        , POTYPE
        , USER2ENT
        , CONFIRM1
        , DOCDATE
        , LSTEDTDT
        , LSTPRTDT
        , PRMDATE
        , PRMSHPDTE
        , REQDATE
        , REQTNDT
        , SHIPMTHD
        , TXRGNNUM
        , REMSUBTO
        , SUBTOTAL
        , TRDISAMT
        , FRTAMNT
        , MSCCHAMT
        , TAXAMNT
        , VENDORID
        , VENDNAME
        , MINORDER
        , VADCDPAD
        , CMPANYID
        , PRBTADCD
        , PRSTADCD
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
        , PYMTRMID
        , DSCDLRAM
        , DSCPCTAM
        , DISAMTAV
        , DISCDATE
        , DUEDATE
        , TRDPCTPR
        , CUSTNMBR
        , TIMESPRT
        , CREATDDT
        , MODIFDT
        , PONOTIDS_1
        , PONOTIDS_2
        , PONOTIDS_3
        , PONOTIDS_4
        , PONOTIDS_5
        , PONOTIDS_6
        , PONOTIDS_7
        , PONOTIDS_8
        , PONOTIDS_9
        , PONOTIDS_10
        , PONOTIDS_11
        , PONOTIDS_12
        , PONOTIDS_13
        , PONOTIDS_14
        , PONOTIDS_15
        , COMMNTID
        , CANCSUB
        , CURNCYID
        , CURRNIDX
        , RATETPID
        , EXGTBLID
        , XCHGRATE
        , EXCHDATE
        , TIME1
        , RATECALC
        , DENXRATE
        , MCTRXSTT
        , OREMSUBT
        , ORSUBTOT
        , ORIGINATING_CANCELED_SUB
        , ORTDISAM
        , ORFRTAMT
        , OMISCAMT
        , ORTAXAMT
        , ORDDLRAT
        , ODISAMTAV
        , BUYERID
        , ONORDAMT
        , ORORDAMT
        , HOLD
        , ONHOLDDATE
        , ONHOLDBY
        , HOLDREMOVEDATE
        , HOLDREMOVEBY
        , ALLOWSOCMTS
        , DISGRPER
        , DUEGRPER
        , REVISION_NUMBER
        , CHANGE_ORDER_FLAG
        , PO_FIELD_CHANGES
        , PO_STATUS_ORIG
        , TAXSCHID
        , TXSCHSRC
        , TXENGCLD
        , BSIVCTTL
        , PURCHASE_FREIGHT_TAXABLE
        , PURCHASE_MISC_TAXABLE
        , FRTSCHID
        , MSCSCHID
        , FRTTXAMT
        , ORFRTTAX
        , MSCTXAMT
        , ORMSCTAX
        , BCKTXAMT
        , OBTAXAMT
        , BACKOUTFREIGHTTAXAMT
        , ORIGBACKOUTFREIGHTTAXAMT
        , BACKOUTMISCTAXAMT
        , ORIGBACKOUTMISCTAXAMT
        , FLAGS
        , BACKOUTTRADEDISCTAX
        , ORIGBACKOUTTRADEDISCTAX
        , POPCONTNUM
        , CONTENDDTE
        , CNTRLBLKTBY
        , PURCHCMPNYNAM
        , PURCHCONTACT
        , PURCHADDRESS1
        , PURCHADDRESS2
        , PURCHADDRESS3
        , PURCHCITY
        , PURCHSTATE
        , PURCHZIPCODE
        , PURCHCCODE
        , PURCHCOUNTRY
        , PURCHPHONE1
        , PURCHPHONE2
        , PURCHPHONE3
        , PURCHFAX
        , BLNKTLINEEXTQTYSUM
        , CBVAT
        , DEX_ROW_ID
        , LEGAL_ENTITY_BK
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PONUMBER as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_HEADER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CMPANYID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LEGAL_ENTITY_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(POSTATUS::text), '^^') 
            , '||', IFNULL(TRIM(STATGRP::text), '^^') 
            , '||', IFNULL(TRIM(POTYPE::text), '^^') 
            , '||', IFNULL(TRIM(USER2ENT::text), '^^') 
            , '||', IFNULL(TRIM(CONFIRM1::text), '^^') 
            , '||', IFNULL(TRIM(DOCDATE::text), '^^') 
            , '||', IFNULL(TRIM(LSTEDTDT::text), '^^') 
            , '||', IFNULL(TRIM(LSTPRTDT::text), '^^') 
            , '||', IFNULL(TRIM(PRMDATE::text), '^^') 
            , '||', IFNULL(TRIM(PRMSHPDTE::text), '^^') 
            , '||', IFNULL(TRIM(REQDATE::text), '^^') 
            , '||', IFNULL(TRIM(REQTNDT::text), '^^') 
            , '||', IFNULL(TRIM(SHIPMTHD::text), '^^') 
            , '||', IFNULL(TRIM(TXRGNNUM::text), '^^') 
            , '||', IFNULL(TRIM(REMSUBTO::text), '^^') 
            , '||', IFNULL(TRIM(SUBTOTAL::text), '^^') 
            , '||', IFNULL(TRIM(TRDISAMT::text), '^^') 
            , '||', IFNULL(TRIM(FRTAMNT::text), '^^') 
            , '||', IFNULL(TRIM(MSCCHAMT::text), '^^') 
            , '||', IFNULL(TRIM(TAXAMNT::text), '^^') 
            , '||', IFNULL(TRIM(VENDORID::text), '^^') 
            , '||', IFNULL(TRIM(VENDNAME::text), '^^') 
            , '||', IFNULL(TRIM(MINORDER::text), '^^') 
            , '||', IFNULL(TRIM(VADCDPAD::text), '^^') 
            , '||', IFNULL(TRIM(CMPANYID::text), '^^') 
            , '||', IFNULL(TRIM(PRBTADCD::text), '^^') 
            , '||', IFNULL(TRIM(PRSTADCD::text), '^^') 
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
            , '||', IFNULL(TRIM(PYMTRMID::text), '^^') 
            , '||', IFNULL(TRIM(DSCDLRAM::text), '^^') 
            , '||', IFNULL(TRIM(DSCPCTAM::text), '^^') 
            , '||', IFNULL(TRIM(DISAMTAV::text), '^^') 
            , '||', IFNULL(TRIM(DISCDATE::text), '^^') 
            , '||', IFNULL(TRIM(DUEDATE::text), '^^') 
            , '||', IFNULL(TRIM(TRDPCTPR::text), '^^') 
            , '||', IFNULL(TRIM(CUSTNMBR::text), '^^') 
            , '||', IFNULL(TRIM(TIMESPRT::text), '^^') 
            , '||', IFNULL(TRIM(CREATDDT::text), '^^') 
            , '||', IFNULL(TRIM(MODIFDT::text), '^^') 
            , '||', IFNULL(TRIM(PONOTIDS_1::text), '^^') 
            , '||', IFNULL(TRIM(PONOTIDS_2::text), '^^') 
            , '||', IFNULL(TRIM(PONOTIDS_3::text), '^^') 
            , '||', IFNULL(TRIM(PONOTIDS_4::text), '^^') 
            , '||', IFNULL(TRIM(PONOTIDS_5::text), '^^') 
            , '||', IFNULL(TRIM(PONOTIDS_6::text), '^^') 
            , '||', IFNULL(TRIM(PONOTIDS_7::text), '^^') 
            , '||', IFNULL(TRIM(PONOTIDS_8::text), '^^') 
            , '||', IFNULL(TRIM(PONOTIDS_9::text), '^^') 
            , '||', IFNULL(TRIM(PONOTIDS_10::text), '^^') 
            , '||', IFNULL(TRIM(PONOTIDS_11::text), '^^') 
            , '||', IFNULL(TRIM(PONOTIDS_12::text), '^^') 
            , '||', IFNULL(TRIM(PONOTIDS_13::text), '^^') 
            , '||', IFNULL(TRIM(PONOTIDS_14::text), '^^') 
            , '||', IFNULL(TRIM(PONOTIDS_15::text), '^^') 
            , '||', IFNULL(TRIM(COMMNTID::text), '^^') 
            , '||', IFNULL(TRIM(CANCSUB::text), '^^') 
            , '||', IFNULL(TRIM(CURNCYID::text), '^^') 
            , '||', IFNULL(TRIM(CURRNIDX::text), '^^') 
            , '||', IFNULL(TRIM(RATETPID::text), '^^') 
            , '||', IFNULL(TRIM(EXGTBLID::text), '^^') 
            , '||', IFNULL(TRIM(XCHGRATE::text), '^^') 
            , '||', IFNULL(TRIM(EXCHDATE::text), '^^') 
            , '||', IFNULL(TRIM(TIME1::text), '^^') 
            , '||', IFNULL(TRIM(RATECALC::text), '^^') 
            , '||', IFNULL(TRIM(DENXRATE::text), '^^') 
            , '||', IFNULL(TRIM(MCTRXSTT::text), '^^') 
            , '||', IFNULL(TRIM(OREMSUBT::text), '^^') 
            , '||', IFNULL(TRIM(ORSUBTOT::text), '^^') 
            , '||', IFNULL(TRIM(ORIGINATING_CANCELED_SUB::text), '^^') 
            , '||', IFNULL(TRIM(ORTDISAM::text), '^^') 
            , '||', IFNULL(TRIM(ORFRTAMT::text), '^^') 
            , '||', IFNULL(TRIM(OMISCAMT::text), '^^') 
            , '||', IFNULL(TRIM(ORTAXAMT::text), '^^') 
            , '||', IFNULL(TRIM(ORDDLRAT::text), '^^') 
            , '||', IFNULL(TRIM(ODISAMTAV::text), '^^') 
            , '||', IFNULL(TRIM(BUYERID::text), '^^') 
            , '||', IFNULL(TRIM(ONORDAMT::text), '^^') 
            , '||', IFNULL(TRIM(ORORDAMT::text), '^^') 
            , '||', IFNULL(TRIM(HOLD::text), '^^') 
            , '||', IFNULL(TRIM(ONHOLDDATE::text), '^^') 
            , '||', IFNULL(TRIM(ONHOLDBY::text), '^^') 
            , '||', IFNULL(TRIM(HOLDREMOVEDATE::text), '^^') 
            , '||', IFNULL(TRIM(HOLDREMOVEBY::text), '^^') 
            , '||', IFNULL(TRIM(ALLOWSOCMTS::text), '^^') 
            , '||', IFNULL(TRIM(DISGRPER::text), '^^') 
            , '||', IFNULL(TRIM(DUEGRPER::text), '^^') 
            , '||', IFNULL(TRIM(REVISION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(CHANGE_ORDER_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PO_FIELD_CHANGES::text), '^^') 
            , '||', IFNULL(TRIM(PO_STATUS_ORIG::text), '^^') 
            , '||', IFNULL(TRIM(TAXSCHID::text), '^^') 
            , '||', IFNULL(TRIM(TXSCHSRC::text), '^^') 
            , '||', IFNULL(TRIM(TXENGCLD::text), '^^') 
            , '||', IFNULL(TRIM(BSIVCTTL::text), '^^') 
            , '||', IFNULL(TRIM(PURCHASE_FREIGHT_TAXABLE::text), '^^') 
            , '||', IFNULL(TRIM(PURCHASE_MISC_TAXABLE::text), '^^') 
            , '||', IFNULL(TRIM(FRTSCHID::text), '^^') 
            , '||', IFNULL(TRIM(MSCSCHID::text), '^^') 
            , '||', IFNULL(TRIM(FRTTXAMT::text), '^^') 
            , '||', IFNULL(TRIM(ORFRTTAX::text), '^^') 
            , '||', IFNULL(TRIM(MSCTXAMT::text), '^^') 
            , '||', IFNULL(TRIM(ORMSCTAX::text), '^^') 
            , '||', IFNULL(TRIM(BCKTXAMT::text), '^^') 
            , '||', IFNULL(TRIM(OBTAXAMT::text), '^^') 
            , '||', IFNULL(TRIM(BACKOUTFREIGHTTAXAMT::text), '^^') 
            , '||', IFNULL(TRIM(ORIGBACKOUTFREIGHTTAXAMT::text), '^^') 
            , '||', IFNULL(TRIM(BACKOUTMISCTAXAMT::text), '^^') 
            , '||', IFNULL(TRIM(ORIGBACKOUTMISCTAXAMT::text), '^^') 
            , '||', IFNULL(TRIM(FLAGS::text), '^^') 
            , '||', IFNULL(TRIM(BACKOUTTRADEDISCTAX::text), '^^') 
            , '||', IFNULL(TRIM(ORIGBACKOUTTRADEDISCTAX::text), '^^') 
            , '||', IFNULL(TRIM(POPCONTNUM::text), '^^') 
            , '||', IFNULL(TRIM(CONTENDDTE::text), '^^') 
            , '||', IFNULL(TRIM(CNTRLBLKTBY::text), '^^') 
            , '||', IFNULL(TRIM(PURCHCMPNYNAM::text), '^^') 
            , '||', IFNULL(TRIM(PURCHCONTACT::text), '^^') 
            , '||', IFNULL(TRIM(PURCHADDRESS1::text), '^^') 
            , '||', IFNULL(TRIM(PURCHADDRESS2::text), '^^') 
            , '||', IFNULL(TRIM(PURCHADDRESS3::text), '^^') 
            , '||', IFNULL(TRIM(PURCHCITY::text), '^^') 
            , '||', IFNULL(TRIM(PURCHSTATE::text), '^^') 
            , '||', IFNULL(TRIM(PURCHZIPCODE::text), '^^') 
            , '||', IFNULL(TRIM(PURCHCCODE::text), '^^') 
            , '||', IFNULL(TRIM(PURCHCOUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(PURCHPHONE1::text), '^^') 
            , '||', IFNULL(TRIM(PURCHPHONE2::text), '^^') 
            , '||', IFNULL(TRIM(PURCHPHONE3::text), '^^') 
            , '||', IFNULL(TRIM(PURCHFAX::text), '^^') 
            , '||', IFNULL(TRIM(BLNKTLINEEXTQTYSUM::text), '^^') 
            , '||', IFNULL(TRIM(CBVAT::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
