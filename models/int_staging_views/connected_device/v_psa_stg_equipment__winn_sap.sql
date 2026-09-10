---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_equi') }} as SRC  ),
SRC_ref_bkcc       as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC 
                        WHERE rec_src = 'US.SAP_ECC_PRD.Z_EQUI' )

/*
SRC_SRC            as ( SELECT * FROM sap_ecc_prd.z_equi )
SRC_ref_bkcc       as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        EQUNR                                                        as                                       EQUIPMENT_BK
      , EQUNR
      , MANDT
      , ERDAT
      , ERNAM
      , EQASP
      , AEDAT
      , AENAM
      , BEGRU
      , EQTYP
      , EQART
      , LVORM
      , INVNR
      , GROES
      , BRGEW
      , GEWEI
      , ANSDT
      , ANSWT
      , WAERS
      , ELIEF
      , GWLEN
      , GWLDT
      , WDBWT
      , HERST
      , HERLD
      , HZEIN
      , SERGE
      , TYPBZ
      , BAUJJ
      , BAUMM
      , APLKZ
      , AULDT
      , INBDT
      , GERNR
      , EQLFN
      , GWLDV
      , EQDAT
      , EQBER
      , EQNUM
      , OBJNR
      , EQSNR
      , CUOBJ
      , KRFKZ
      , KMATN
      , MATNR
      , SERNR
      , WERK
      , LAGER
      , CHARGE
      , KUNDE
      , WARPL
      , IMRC_POINT
      , REVLV
      , MGANR
      , BEGRUI
      , S_EQUI
      , S_SERIAL
      , S_KONFI
      , S_SALE
      , S_FHM
      , S_ELSE
      , S_ISU
      , S_EQBS
      , S_FLEET
      , BSTVP
      , SPARTE
      , HANDLE
      , TSEGTP
      , EMATN
      , ACT_CHANGE_AA
      , S_CC
      , DATLWB
      , UII
      , IUID_TYPE
      , UII_PLANT
      , EQEXT_ACTIVE
      , EQUI_SRTYPE
      , EQUI_SNTYPE
      , EQLB_DUTY
      , EQLB_HIDE
      , GLREQUEST
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, CONVERT_TIMEZONE('UTC', TO_TIMESTAMP_NTZ(SUBSTR(GLCHANGETIME, 1, 14) || '.' || SUBSTR(GLCHANGETIME, 16), 'YYYYMMDDHH24MISS.FF9'))) as                                           LOAD_DTS
    FROM SRC_SRC
)

, LOGIC_ref_bkcc as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_ref_bkcc
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM LOGIC_SRC
    INNER JOIN LOGIC_ref_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          EQUIPMENT_BK
        , EQUNR
        , MANDT
        , ERDAT
        , ERNAM
        , EQASP
        , AEDAT
        , AENAM
        , BEGRU
        , EQTYP
        , EQART
        , LVORM
        , INVNR
        , GROES
        , BRGEW
        , GEWEI
        , ANSDT
        , ANSWT
        , WAERS
        , ELIEF
        , GWLEN
        , GWLDT
        , WDBWT
        , HERST
        , HERLD
        , HZEIN
        , SERGE
        , TYPBZ
        , BAUJJ
        , BAUMM
        , APLKZ
        , AULDT
        , INBDT
        , GERNR
        , EQLFN
        , GWLDV
        , EQDAT
        , EQBER
        , EQNUM
        , OBJNR
        , EQSNR
        , CUOBJ
        , KRFKZ
        , KMATN
        , MATNR
        , SERNR
        , WERK
        , LAGER
        , CHARGE
        , KUNDE
        , WARPL
        , IMRC_POINT
        , REVLV
        , MGANR
        , BEGRUI
        , S_EQUI
        , S_SERIAL
        , S_KONFI
        , S_SALE
        , S_FHM
        , S_ELSE
        , S_ISU
        , S_EQBS
        , S_FLEET
        , BSTVP
        , SPARTE
        , HANDLE
        , TSEGTP
        , EMATN
        , ACT_CHANGE_AA
        , S_CC
        , DATLWB
        , UII
        , IUID_TYPE
        , UII_PLANT
        , EQEXT_ACTIVE
        , EQUI_SRTYPE
        , EQUI_SNTYPE
        , EQLB_DUTY
        , EQLB_HIDE
        , GLREQUEST
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , BKCC
        , REC_SRC
        , LOAD_DTS
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(EQUNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as EQUIPMENT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(ERDAT::text), '^^') 
            , '||', IFNULL(TRIM(ERNAM::text), '^^') 
            , '||', IFNULL(TRIM(EQASP::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT::text), '^^') 
            , '||', IFNULL(TRIM(AENAM::text), '^^') 
            , '||', IFNULL(TRIM(BEGRU::text), '^^') 
            , '||', IFNULL(TRIM(EQTYP::text), '^^') 
            , '||', IFNULL(TRIM(EQART::text), '^^') 
            , '||', IFNULL(TRIM(LVORM::text), '^^') 
            , '||', IFNULL(TRIM(INVNR::text), '^^') 
            , '||', IFNULL(TRIM(GROES::text), '^^') 
            , '||', IFNULL(TRIM(BRGEW::text), '^^') 
            , '||', IFNULL(TRIM(GEWEI::text), '^^') 
            , '||', IFNULL(TRIM(ANSDT::text), '^^') 
            , '||', IFNULL(TRIM(ANSWT::text), '^^') 
            , '||', IFNULL(TRIM(WAERS::text), '^^') 
            , '||', IFNULL(TRIM(ELIEF::text), '^^') 
            , '||', IFNULL(TRIM(GWLEN::text), '^^') 
            , '||', IFNULL(TRIM(GWLDT::text), '^^') 
            , '||', IFNULL(TRIM(WDBWT::text), '^^') 
            , '||', IFNULL(TRIM(HERST::text), '^^') 
            , '||', IFNULL(TRIM(HERLD::text), '^^') 
            , '||', IFNULL(TRIM(HZEIN::text), '^^') 
            , '||', IFNULL(TRIM(SERGE::text), '^^') 
            , '||', IFNULL(TRIM(TYPBZ::text), '^^') 
            , '||', IFNULL(TRIM(BAUJJ::text), '^^') 
            , '||', IFNULL(TRIM(BAUMM::text), '^^') 
            , '||', IFNULL(TRIM(APLKZ::text), '^^') 
            , '||', IFNULL(TRIM(AULDT::text), '^^') 
            , '||', IFNULL(TRIM(INBDT::text), '^^') 
            , '||', IFNULL(TRIM(GERNR::text), '^^') 
            , '||', IFNULL(TRIM(EQLFN::text), '^^') 
            , '||', IFNULL(TRIM(GWLDV::text), '^^') 
            , '||', IFNULL(TRIM(EQDAT::text), '^^') 
            , '||', IFNULL(TRIM(EQBER::text), '^^') 
            , '||', IFNULL(TRIM(EQNUM::text), '^^') 
            , '||', IFNULL(TRIM(OBJNR::text), '^^') 
            , '||', IFNULL(TRIM(EQSNR::text), '^^') 
            , '||', IFNULL(TRIM(CUOBJ::text), '^^') 
            , '||', IFNULL(TRIM(KRFKZ::text), '^^') 
            , '||', IFNULL(TRIM(KMATN::text), '^^') 
            , '||', IFNULL(TRIM(MATNR::text), '^^') 
            , '||', IFNULL(TRIM(SERNR::text), '^^') 
            , '||', IFNULL(TRIM(WERK::text), '^^') 
            , '||', IFNULL(TRIM(LAGER::text), '^^') 
            , '||', IFNULL(TRIM(CHARGE::text), '^^') 
            , '||', IFNULL(TRIM(KUNDE::text), '^^') 
            , '||', IFNULL(TRIM(WARPL::text), '^^') 
            , '||', IFNULL(TRIM(IMRC_POINT::text), '^^') 
            , '||', IFNULL(TRIM(REVLV::text), '^^') 
            , '||', IFNULL(TRIM(MGANR::text), '^^') 
            , '||', IFNULL(TRIM(BEGRUI::text), '^^') 
            , '||', IFNULL(TRIM(S_EQUI::text), '^^') 
            , '||', IFNULL(TRIM(S_SERIAL::text), '^^') 
            , '||', IFNULL(TRIM(S_KONFI::text), '^^') 
            , '||', IFNULL(TRIM(S_SALE::text), '^^') 
            , '||', IFNULL(TRIM(S_FHM::text), '^^') 
            , '||', IFNULL(TRIM(S_ELSE::text), '^^') 
            , '||', IFNULL(TRIM(S_ISU::text), '^^') 
            , '||', IFNULL(TRIM(S_EQBS::text), '^^') 
            , '||', IFNULL(TRIM(S_FLEET::text), '^^') 
            , '||', IFNULL(TRIM(BSTVP::text), '^^') 
            , '||', IFNULL(TRIM(SPARTE::text), '^^') 
            , '||', IFNULL(TRIM(HANDLE::text), '^^') 
            , '||', IFNULL(TRIM(TSEGTP::text), '^^') 
            , '||', IFNULL(TRIM(EMATN::text), '^^') 
            , '||', IFNULL(TRIM(ACT_CHANGE_AA::text), '^^') 
            , '||', IFNULL(TRIM(S_CC::text), '^^') 
            , '||', IFNULL(TRIM(DATLWB::text), '^^') 
            , '||', IFNULL(TRIM(UII::text), '^^') 
            , '||', IFNULL(TRIM(IUID_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(UII_PLANT::text), '^^') 
            , '||', IFNULL(TRIM(EQEXT_ACTIVE::text), '^^') 
            , '||', IFNULL(TRIM(EQUI_SRTYPE::text), '^^') 
            , '||', IFNULL(TRIM(EQUI_SNTYPE::text), '^^') 
            , '||', IFNULL(TRIM(EQLB_DUTY::text), '^^') 
            , '||', IFNULL(TRIM(EQLB_HIDE::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
