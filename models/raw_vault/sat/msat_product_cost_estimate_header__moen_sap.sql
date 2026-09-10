---- SRC LAYER ----
WITH
SRC_CEH            as ( SELECT * FROM {{ ref('v_psa_stg_cost_estimate_header__moen_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_CEH            as ( SELECT * FROM STAGING.v_psa_stg_cost_estimate_header__moen_sap )
*/
---- LOGIC LAYER ----

, LOGIC_CEH as (
    SELECT
        MATNR
      , BZOBJ
      , KALNR
      , BWVAR
      , KKZMA
      , KADKY
      , LOAD_DTS
      , KALKA
      , TVERS
      , ITEM_HK
      , WERKS
      , PLANT_HK
      , BWKEY
      , BWTAR
      , KOKRS
      , KADAT
      , BIDAT
      , KADAM
      , BIDAM
      , BWDAT
      , ALDAT
      , BEDAT
      , VERID
      , STNUM
      , STLAN
      , STALT
      , STCNT
      , PLNNR
      , PLNTY
      , PLNAL
      , PLNCT
      , LOEKZ
      , LOSGR
      , MEINS
      , ERFNM
      , ERFMA
      , CPUDT
      , CPUDM
      , CPUTIME
      , FEH_ANZ
      , FEH_K_ANZ
      , FEH_STA
      , MAXMSG
      , FREIG
      , MKALK
      , BALTKZ
      , KALNR_BA
      , BTYP
      , MISCH_VERH
      , BWVAR_BA
      , PLSCN
      , PLMNG
      , SOBSL
      , SOBES
      , SOWRK
      , SOBWT
      , SODIR
      , SODUM
      , KALSM
      , AUFZA
      , BWSMR
      , SUBSTRAT
      , KLVAR
      , KOSGR
      , ZSCHL
      , POPER
      , BDATJ
      , STKOZ
      , ZAEHL
      , TOPKA
      , CMF_NR
      , OCS_COUNT
      , OBJNR
      , ERZKA
      , LOSAU
      , AUSID
      , AUSSS
      , SAPRL
      , KZROH
      , AUFPL
      , CUOBJ
      , CUOBJID
      , TECHS
      , TYPE
      , WRKLT
      , VORMDAT
      , VORMUSR
      , FREIDAT
      , FREIUSR
      , UEBID
      , PROZESS
      , PR_VERID
      , CSPLIT
      , KZKUP
      , FXPRU
      , CFXPR
      , ZIFFR
      , SUMZIFFR
      , AFAKT
      , VBELN
      , POSNR
      , PSPNR
      , SBDKZ
      , MLMAA
      , BESKZ
      , DISST
      , KALST
      , TEMPLATE
      , PATNR
      , PART_VRSN
      , ELEHK
      , ELEHKNS
      , VOCNT
      , GSBER
      , PRCTR
      , TPVAR
      , KURST
      , MGTYP
      , HWAER
      , FWAER_KPF
      , REFID
      , MEINH_WS
      , KZWSO
      , ASL
      , KALAID
      , KALADAT
      , OTYP
      , BAPI_CREATED
      , SGT_SCAT
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PRODUCT_COST_ESTIMATE_HK
      , HASHDIFF
      , REC_SRC
      , BKCC
    FROM SRC_CEH
)
---- RENAME LAYER ----

, RENAME_CEH as (
    SELECT
        MATNR
      , BZOBJ
      , KALNR
      , BWVAR
      , KKZMA
      , KADKY
      , LOAD_DTS
      , KALKA
      , TVERS
      , ITEM_HK
      , WERKS
      , PLANT_HK
      , BWKEY
      , BWTAR
      , KOKRS
      , KADAT
      , BIDAT
      , KADAM
      , BIDAM
      , BWDAT
      , ALDAT
      , BEDAT
      , VERID
      , STNUM
      , STLAN
      , STALT
      , STCNT
      , PLNNR
      , PLNTY
      , PLNAL
      , PLNCT
      , LOEKZ
      , LOSGR
      , MEINS
      , ERFNM
      , ERFMA
      , CPUDT
      , CPUDM
      , CPUTIME
      , FEH_ANZ
      , FEH_K_ANZ
      , FEH_STA
      , MAXMSG
      , FREIG
      , MKALK
      , BALTKZ
      , KALNR_BA
      , BTYP
      , MISCH_VERH
      , BWVAR_BA
      , PLSCN
      , PLMNG
      , SOBSL
      , SOBES
      , SOWRK
      , SOBWT
      , SODIR
      , SODUM
      , KALSM
      , AUFZA
      , BWSMR
      , SUBSTRAT
      , KLVAR
      , KOSGR
      , ZSCHL
      , POPER
      , BDATJ
      , STKOZ
      , ZAEHL
      , TOPKA
      , CMF_NR
      , OCS_COUNT
      , OBJNR
      , ERZKA
      , LOSAU
      , AUSID
      , AUSSS
      , SAPRL
      , KZROH
      , AUFPL
      , CUOBJ
      , CUOBJID
      , TECHS
      , TYPE
      , WRKLT
      , VORMDAT
      , VORMUSR
      , FREIDAT
      , FREIUSR
      , UEBID
      , PROZESS
      , PR_VERID
      , CSPLIT
      , KZKUP
      , FXPRU
      , CFXPR
      , ZIFFR
      , SUMZIFFR
      , AFAKT
      , VBELN
      , POSNR
      , PSPNR
      , SBDKZ
      , MLMAA
      , BESKZ
      , DISST
      , KALST
      , TEMPLATE
      , PATNR
      , PART_VRSN
      , ELEHK
      , ELEHKNS
      , VOCNT
      , GSBER
      , PRCTR
      , TPVAR
      , KURST
      , MGTYP
      , HWAER
      , FWAER_KPF
      , REFID
      , MEINH_WS
      , KZWSO
      , ASL
      , KALAID
      , KALADAT
      , OTYP
      , BAPI_CREATED
      , SGT_SCAT
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PRODUCT_COST_ESTIMATE_HK
      , HASHDIFF
      , REC_SRC
      , BKCC
    FROM LOGIC_CEH
)
---- FILTER LAYER ----

, FILTER_CEH as (
    SELECT *
    FROM RENAME_CEH
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_CEH
)

---- FINAL LAYER ----
SELECT
          MATNR
        , BZOBJ
        , KALNR
        , BWVAR
        , KKZMA
        , KADKY
        , LOAD_DTS
        , KALKA
        , TVERS
        , ITEM_HK
        , WERKS
        , PLANT_HK
        , BWKEY
        , BWTAR
        , KOKRS
        , KADAT
        , BIDAT
        , KADAM
        , BIDAM
        , BWDAT
        , ALDAT
        , BEDAT
        , VERID
        , STNUM
        , STLAN
        , STALT
        , STCNT
        , PLNNR
        , PLNTY
        , PLNAL
        , PLNCT
        , LOEKZ
        , LOSGR
        , MEINS
        , ERFNM
        , ERFMA
        , CPUDT
        , CPUDM
        , CPUTIME
        , FEH_ANZ
        , FEH_K_ANZ
        , FEH_STA
        , MAXMSG
        , FREIG
        , MKALK
        , BALTKZ
        , KALNR_BA
        , BTYP
        , MISCH_VERH
        , BWVAR_BA
        , PLSCN
        , PLMNG
        , SOBSL
        , SOBES
        , SOWRK
        , SOBWT
        , SODIR
        , SODUM
        , KALSM
        , AUFZA
        , BWSMR
        , SUBSTRAT
        , KLVAR
        , KOSGR
        , ZSCHL
        , POPER
        , BDATJ
        , STKOZ
        , ZAEHL
        , TOPKA
        , CMF_NR
        , OCS_COUNT
        , OBJNR
        , ERZKA
        , LOSAU
        , AUSID
        , AUSSS
        , SAPRL
        , KZROH
        , AUFPL
        , CUOBJ
        , CUOBJID
        , TECHS
        , TYPE
        , WRKLT
        , VORMDAT
        , VORMUSR
        , FREIDAT
        , FREIUSR
        , UEBID
        , PROZESS
        , PR_VERID
        , CSPLIT
        , KZKUP
        , FXPRU
        , CFXPR
        , ZIFFR
        , SUMZIFFR
        , AFAKT
        , VBELN
        , POSNR
        , PSPNR
        , SBDKZ
        , MLMAA
        , BESKZ
        , DISST
        , KALST
        , TEMPLATE
        , PATNR
        , PART_VRSN
        , ELEHK
        , ELEHKNS
        , VOCNT
        , GSBER
        , PRCTR
        , TPVAR
        , KURST
        , MGTYP
        , HWAER
        , FWAER_KPF
        , REFID
        , MEINH_WS
        , KZWSO
        , ASL
        , KALAID
        , KALADAT
        , OTYP
        , BAPI_CREATED
        , SGT_SCAT
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , PRODUCT_COST_ESTIMATE_HK
        , HASHDIFF
        , REC_SRC
        , BKCC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.MATNR = JOIN_RESULT.MATNR 
	AND existing.BZOBJ=JOIN_RESULT.BZOBJ
	AND existing.KALNR=JOIN_RESULT.KALNR
	AND existing.BWVAR=JOIN_RESULT.BWVAR
	AND existing.KKZMA=JOIN_RESULT.KKZMA
	AND existing.KADKY=JOIN_RESULT.KADKY
	AND existing.KALKA=JOIN_RESULT.KALKA
	AND existing.TVERS=JOIN_RESULT.TVERS
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	)
{% endif %}



{% if not is_incremental() %}
qualify 1=row_number() over(partition by MATNR,BZOBJ,KALNR,BWVAR,KKZMA,KADKY,KALKA,TVERS, hashdiff order by PSA_LOAD_DTS)
{% endif %}
{% if not is_incremental() %}
UNION ALL
SELECT
GR.VALUE AS MATNR,
GR.VALUE AS BZOBJ,
GR.VALUE AS KALNR,
GR.VALUE AS BWVAR,
GR.VALUE AS KKZMA,
GR.VALUE AS KADKY,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP_LTZ) AS LOAD_DTS,
GR.VALUE AS KALKA,
GR.VALUE AS TVERS,
MD5_BINARY(GR.VALUE) AS ITEM_HK,
GR.VALUE AS WERKS,
MD5_BINARY(GR.VALUE) AS PLANT_HK,
NULL AS BWKEY,
NULL AS BWTAR,
NULL AS KOKRS,
NULL AS KADAT,
NULL AS BIDAT,
NULL AS KADAM,
NULL AS BIDAM,
NULL AS BWDAT,
NULL AS ALDAT,
NULL AS BEDAT,
NULL AS VERID,
NULL AS STNUM,
NULL AS STLAN,
NULL AS STALT,
NULL AS STCNT,
NULL AS PLNNR,
NULL AS PLNTY,
NULL AS PLNAL,
NULL AS PLNCT,
NULL AS LOEKZ,
NULL AS LOSGR,
NULL AS MEINS,
NULL AS ERFNM,
NULL AS ERFMA,
NULL AS CPUDT,
NULL AS CPUDM,
NULL AS CPUTIME,
NULL AS FEH_ANZ,
NULL AS FEH_K_ANZ,
NULL AS FEH_STA,
NULL AS MAXMSG,
NULL AS FREIG,
NULL AS MKALK,
NULL AS BALTKZ,
NULL AS KALNR_BA,
NULL AS BTYP,
NULL AS MISCH_VERH,
NULL AS BWVAR_BA,
NULL AS PLSCN,
NULL AS PLMNG,
NULL AS SOBSL,
NULL AS SOBES,
NULL AS SOWRK,
NULL AS SOBWT,
NULL AS SODIR,
NULL AS SODUM,
NULL AS KALSM,
NULL AS AUFZA,
NULL AS BWSMR,
NULL AS SUBSTRAT,
NULL AS KLVAR,
NULL AS KOSGR,
NULL AS ZSCHL,
NULL AS POPER,
NULL AS BDATJ,
NULL AS STKOZ,
NULL AS ZAEHL,
NULL AS TOPKA,
NULL AS CMF_NR,
NULL AS OCS_COUNT,
NULL AS OBJNR,
NULL AS ERZKA,
NULL AS LOSAU,
NULL AS AUSID,
NULL AS AUSSS,
NULL AS SAPRL,
NULL AS KZROH,
NULL AS AUFPL,
NULL AS CUOBJ,
NULL AS CUOBJID,
NULL AS TECHS,
NULL AS TYPE,
NULL AS WRKLT,
NULL AS VORMDAT,
NULL AS VORMUSR,
NULL AS FREIDAT,
NULL AS FREIUSR,
NULL AS UEBID,
NULL AS PROZESS,
NULL AS PR_VERID,
NULL AS CSPLIT,
NULL AS KZKUP,
NULL AS FXPRU,
NULL AS CFXPR,
NULL AS ZIFFR,
NULL AS SUMZIFFR,
NULL AS AFAKT,
NULL AS VBELN,
NULL AS POSNR,
NULL AS PSPNR,
NULL AS SBDKZ,
NULL AS MLMAA,
NULL AS BESKZ,
NULL AS DISST,
NULL AS KALST,
NULL AS TEMPLATE,
NULL AS PATNR,
NULL AS PART_VRSN,
NULL AS ELEHK,
NULL AS ELEHKNS,
NULL AS VOCNT,
NULL AS GSBER,
NULL AS PRCTR,
NULL AS TPVAR,
NULL AS KURST,
NULL AS MGTYP,
NULL AS HWAER,
NULL AS FWAER_KPF,
NULL AS REFID,
NULL AS MEINH_WS,
NULL AS KZWSO,
NULL AS ASL,
NULL AS KALAID,
NULL AS KALADAT,
NULL AS OTYP,
NULL AS BAPI_CREATED,
NULL AS SGT_SCAT,
NULL AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
NULL AS PSA_DELETE_IND,
MD5_BINARY(GR.VALUE) AS PRODUCT_COST_ESTIMATE_HK,
MD5_BINARY(GR.VALUE) AS HASHDIFF,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC
FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}