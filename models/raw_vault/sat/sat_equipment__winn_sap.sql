---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ ref('v_psa_stg_equipment__winn_sap') }} as SRC 
{% if is_incremental() %}
      where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
    {% endif %} )

/*
SRC_SRC            as ( SELECT * FROM int_staging_views.v_psa_stg_equipment__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        EQUIPMENT_HK
      , EQUNR
      , MANDT
      , GLREQUEST
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
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_SRC
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM LOGIC_SRC
)

---- FINAL LAYER ----
SELECT
          EQUIPMENT_HK
        , EQUNR
        , MANDT
        , GLREQUEST
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
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} existing
    WHERE existing.EQUIPMENT_HK = JOIN_RESULT.EQUIPMENT_HK
      AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by EQUIPMENT_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS EQUIPMENT_HK,
NULL AS EQUNR,
NULL AS MANDT,
NULL AS GLREQUEST,
NULL AS ERDAT,
NULL AS ERNAM,
NULL AS EQASP,
NULL AS AEDAT,
NULL AS AENAM,
NULL AS BEGRU,
NULL AS EQTYP,
NULL AS EQART,
NULL AS LVORM,
NULL AS INVNR,
NULL AS GROES,
NULL AS BRGEW,
NULL AS GEWEI,
NULL AS ANSDT,
NULL AS ANSWT,
NULL AS WAERS,
NULL AS ELIEF,
NULL AS GWLEN,
NULL AS GWLDT,
NULL AS WDBWT,
NULL AS HERST,
NULL AS HERLD,
NULL AS HZEIN,
NULL AS SERGE,
NULL AS TYPBZ,
NULL AS BAUJJ,
NULL AS BAUMM,
NULL AS APLKZ,
NULL AS AULDT,
NULL AS INBDT,
NULL AS GERNR,
NULL AS EQLFN,
NULL AS GWLDV,
NULL AS EQDAT,
NULL AS EQBER,
NULL AS EQNUM,
NULL AS OBJNR,
NULL AS EQSNR,
NULL AS CUOBJ,
NULL AS KRFKZ,
NULL AS KMATN,
NULL AS MATNR,
NULL AS SERNR,
NULL AS WERK,
NULL AS LAGER,
NULL AS CHARGE,
NULL AS KUNDE,
NULL AS WARPL,
NULL AS IMRC_POINT,
NULL AS REVLV,
NULL AS MGANR,
NULL AS BEGRUI,
NULL AS S_EQUI,
NULL AS S_SERIAL,
NULL AS S_KONFI,
NULL AS S_SALE,
NULL AS S_FHM,
NULL AS S_ELSE,
NULL AS S_ISU,
NULL AS S_EQBS,
NULL AS S_FLEET,
NULL AS BSTVP,
NULL AS SPARTE,
NULL AS HANDLE,
NULL AS TSEGTP,
NULL AS EMATN,
NULL AS ACT_CHANGE_AA,
NULL AS S_CC,
NULL AS DATLWB,
NULL AS UII,
NULL AS IUID_TYPE,
NULL AS UII_PLANT,
NULL AS EQEXT_ACTIVE,
NULL AS EQUI_SRTYPE,
NULL AS EQUI_SNTYPE,
NULL AS EQLB_DUTY,
NULL AS EQLB_HIDE,
NULL AS GLDELFLAG,
NULL AS GLSOURCESYSTEM,
NULL AS GLCHANGETIME,
'N' AS PSA_DELETE_IND,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'1900-01-01T00:00:00'::TIMESTAMP_NTZ AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
MD5_BINARY('') AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
