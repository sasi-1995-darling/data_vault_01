---- SRC LAYER ----
WITH
SRC_SWINN          as ( SELECT * FROM {{ ref('v_psa_stg_legal_entity__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SWINN          as ( SELECT * FROM STAGING.v_psa_stg_legal_entity__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_SWINN as (
    SELECT
        LEGAL_ENTITY_HK
      , LOAD_DTS
      , MANDT
      , BUKRS
      , GLREQUEST
      , BUTXT
      , ORT01
      , LAND1
      , WAERS
      , SPRAS
      , KTOPL
      , WAABW
      , PERIV
      , KOKFI
      , RCOMP
      , ADRNR
      , STCEG
      , FIKRS
      , XFMCO
      , XFMCB
      , XFMCA
      , TXJCD
      , FMHRDATE
      , BUVAR
      , FDBUK
      , XFDIS
      , XVALV
      , XSKFN
      , KKBER
      , XMWSN
      , MREGL
      , XGSBE
      , XGJRV
      , XKDFT
      , XPROD
      , XEINK
      , XJVAA
      , XVVWA
      , XSLTA
      , XFDMM
      , XFDSD
      , XEXTB
      , EBUKR
      , KTOP2
      , UMKRS
      , BUKRS_GLOB
      , FSTVA
      , OPVAR
      , XCOVR
      , TXKRS
      , WFVAR
      , XBBBF
      , XBBBE
      , XBBBA
      , XBBKO
      , XSTDT
      , MWSKV
      , MWSKA
      , IMPDA
      , XNEGP
      , XKKBI
      , WT_NEWWT
      , PP_PDATE
      , INFMT
      , FSTVARE
      , KOPIM
      , DKWEG
      , OFFSACCT
      , BAPOVAR
      , XCOS
      , XCESSION
      , XSPLT
      , SURCCM
      , DTPROV
      , DTAMTC
      , DTTAXC
      , DTTDSP
      , DTAXR
      , XVATDATE
      , PST_PER_VAR
      , XBBSC
      , FM_DERIVE_ACC
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_SWINN
)
---- RENAME LAYER ----

, RENAME_SWINN as (
    SELECT
        LEGAL_ENTITY_HK
      , LOAD_DTS
      , MANDT
      , BUKRS
      , GLREQUEST
      , BUTXT
      , ORT01
      , LAND1
      , WAERS
      , SPRAS
      , KTOPL
      , WAABW
      , PERIV
      , KOKFI
      , RCOMP
      , ADRNR
      , STCEG
      , FIKRS
      , XFMCO
      , XFMCB
      , XFMCA
      , TXJCD
      , FMHRDATE
      , BUVAR
      , FDBUK
      , XFDIS
      , XVALV
      , XSKFN
      , KKBER
      , XMWSN
      , MREGL
      , XGSBE
      , XGJRV
      , XKDFT
      , XPROD
      , XEINK
      , XJVAA
      , XVVWA
      , XSLTA
      , XFDMM
      , XFDSD
      , XEXTB
      , EBUKR
      , KTOP2
      , UMKRS
      , BUKRS_GLOB
      , FSTVA
      , OPVAR
      , XCOVR
      , TXKRS
      , WFVAR
      , XBBBF
      , XBBBE
      , XBBBA
      , XBBKO
      , XSTDT
      , MWSKV
      , MWSKA
      , IMPDA
      , XNEGP
      , XKKBI
      , WT_NEWWT
      , PP_PDATE
      , INFMT
      , FSTVARE
      , KOPIM
      , DKWEG
      , OFFSACCT
      , BAPOVAR
      , XCOS
      , XCESSION
      , XSPLT
      , SURCCM
      , DTPROV
      , DTAMTC
      , DTTAXC
      , DTTDSP
      , DTAXR
      , XVATDATE
      , PST_PER_VAR
      , XBBSC
      , FM_DERIVE_ACC
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_SWINN
)
---- FILTER LAYER ----

, FILTER_SWINN as (
    SELECT *
    FROM RENAME_SWINN
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SWINN
)

---- FINAL LAYER ----
SELECT
          LEGAL_ENTITY_HK
        , LOAD_DTS
        , MANDT
        , BUKRS
        , GLREQUEST
        , BUTXT
        , ORT01
        , LAND1
        , WAERS
        , SPRAS
        , KTOPL
        , WAABW
        , PERIV
        , KOKFI
        , RCOMP
        , ADRNR
        , STCEG
        , FIKRS
        , XFMCO
        , XFMCB
        , XFMCA
        , TXJCD
        , FMHRDATE
        , BUVAR
        , FDBUK
        , XFDIS
        , XVALV
        , XSKFN
        , KKBER
        , XMWSN
        , MREGL
        , XGSBE
        , XGJRV
        , XKDFT
        , XPROD
        , XEINK
        , XJVAA
        , XVVWA
        , XSLTA
        , XFDMM
        , XFDSD
        , XEXTB
        , EBUKR
        , KTOP2
        , UMKRS
        , BUKRS_GLOB
        , FSTVA
        , OPVAR
        , XCOVR
        , TXKRS
        , WFVAR
        , XBBBF
        , XBBBE
        , XBBBA
        , XBBKO
        , XSTDT
        , MWSKV
        , MWSKA
        , IMPDA
        , XNEGP
        , XKKBI
        , WT_NEWWT
        , PP_PDATE
        , INFMT
        , FSTVARE
        , KOPIM
        , DKWEG
        , OFFSACCT
        , BAPOVAR
        , XCOS
        , XCESSION
        , XSPLT
        , SURCCM
        , DTPROV
        , DTAMTC
        , DTTAXC
        , DTTDSP
        , DTAXR
        , XVATDATE
        , PST_PER_VAR
        , XBBSC
        , FM_DERIVE_ACC
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LEGAL_ENTITY_HK = JOIN_RESULT.LEGAL_ENTITY_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 

{% if not is_incremental() %}
/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1= row_number()over(partition by LEGAL_ENTITY_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
    SELECT 
    MD5_BINARY(GR.VALUE) AS LEGAL_ENTITY_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, NULL AS MANDT
, GR.VALUE AS BUKRS
, NULL AS GLREQUEST
, NULL AS BUTXT
, NULL AS ORT01
, NULL AS LAND1
, NULL AS WAERS
, NULL AS SPRAS
, NULL AS KTOPL
, NULL AS WAABW
, NULL AS PERIV
, NULL AS KOKFI
, NULL AS RCOMP
, NULL AS ADRNR
, NULL AS STCEG
, NULL AS FIKRS
, NULL AS XFMCO
, NULL AS XFMCB
, NULL AS XFMCA
, NULL AS TXJCD
, NULL AS FMHRDATE
, NULL AS BUVAR
, NULL AS FDBUK
, NULL AS XFDIS
, NULL AS XVALV
, NULL AS XSKFN
, NULL AS KKBER
, NULL AS XMWSN
, NULL AS MREGL
, NULL AS XGSBE
, NULL AS XGJRV
, NULL AS XKDFT
, NULL AS XPROD
, NULL AS XEINK
, NULL AS XJVAA
, NULL AS XVVWA
, NULL AS XSLTA
, NULL AS XFDMM
, NULL AS XFDSD
, NULL AS XEXTB
, NULL AS EBUKR
, NULL AS KTOP2
, NULL AS UMKRS
, NULL AS BUKRS_GLOB
, NULL AS FSTVA
, NULL AS OPVAR
, NULL AS XCOVR
, NULL AS TXKRS
, NULL AS WFVAR
, NULL AS XBBBF
, NULL AS XBBBE
, NULL AS XBBBA
, NULL AS XBBKO
, NULL AS XSTDT
, NULL AS MWSKV
, NULL AS MWSKA
, NULL AS IMPDA
, NULL AS XNEGP
, NULL AS XKKBI
, NULL AS WT_NEWWT
, NULL AS PP_PDATE
, NULL AS INFMT
, NULL AS FSTVARE
, NULL AS KOPIM
, NULL AS DKWEG
, NULL AS OFFSACCT
, NULL AS BAPOVAR
, NULL AS XCOS
, NULL AS XCESSION
, NULL AS XSPLT
, NULL AS SURCCM
, NULL AS DTPROV
, NULL AS DTAMTC
, NULL AS DTTAXC
, NULL AS DTTDSP
, NULL AS DTAXR
, NULL AS XVATDATE
, NULL AS PST_PER_VAR
, NULL AS XBBSC
, NULL AS FM_DERIVE_ACC
, NULL AS GLDELFLAG
, NULL AS GLSOURCESYSTEM
, NULL AS GLCHANGETIME
, '1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS
, 'N' AS PSA_DELETE_IND
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, ''::BINARY as HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}