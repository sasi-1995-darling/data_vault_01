---- SRC LAYER ----
WITH
SRC_FA             as ( SELECT * FROM {{ ref('v_psa_stg_material_valuation__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_FA             as ( SELECT * FROM STAGING.v_psa_stg_material_valuation__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_FA as (
    SELECT
        LNK_MATERIAL_VALUATION_HK
      , MANDT
      , MATNR
      , BWKEY
      , BWTAR
      , LVORM
      , LBKUM
      , SALK3
      , VPRSV
      , VERPR
      , STPRS
      , PEINH
      , BKLAS
      , SALKV
      , VMKUM
      , VMSAL
      , VMVPR
      , VMVER
      , VMSTP
      , VMPEI
      , VMBKL
      , VMSAV
      , VJKUM
      , VJSAL
      , VJVPR
      , VJVER
      , VJSTP
      , VJPEI
      , VJBKL
      , VJSAV
      , LFGJA
      , LFMON
      , BWTTY
      , STPRV
      , LAEPR
      , ZKPRS
      , ZKDAT
      , TIMESTAMP
      , BWPRS
      , BWPRH
      , VJBWS
      , VJBWH
      , VVJSL
      , VVJLB
      , VVMLB
      , VVSAL
      , ZPLPR
      , ZPLP1
      , ZPLP2
      , ZPLP3
      , ZPLD1
      , ZPLD2
      , ZPLD3
      , PPERZ
      , PPERL
      , PPERV
      , KALKZ
      , KALKL
      , KALKV
      , KALSC
      , XLIFO
      , MYPOL
      , BWPH1
      , BWPS1
      , ABWKZ
      , PSTAT
      , KALN1
      , KALNR
      , BWVA1
      , BWVA2
      , BWVA3
      , VERS1
      , VERS2
      , VERS3
      , HRKFT
      , KOSGR
      , PPRDZ
      , PPRDL
      , PPRDV
      , PDATZ
      , PDATL
      , PDATV
      , EKALR
      , VPLPR
      , MLMAA
      , MLAST
      , LPLPR
      , VKSAL
      , HKMAT
      , SPERW
      , KZIWL
      , WLINL
      , ABCIW
      , BWSPA
      , LPLPX
      , VPLPX
      , FPLPX
      , LBWST
      , VBWST
      , FBWST
      , EKLAS
      , QKLAS
      , MTUSE
      , MTORG
      , OWNPR
      , XBEWM
      , BWPEI
      , MBRUE
      , OKLAS
      , OIPPINV
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_FA
)
---- RENAME LAYER ----

, RENAME_FA as (
    SELECT
        LNK_MATERIAL_VALUATION_HK
      , MANDT
      , MATNR
      , BWKEY
      , BWTAR
      , LVORM
      , LBKUM
      , SALK3
      , VPRSV
      , VERPR
      , STPRS
      , PEINH
      , BKLAS
      , SALKV
      , VMKUM
      , VMSAL
      , VMVPR
      , VMVER
      , VMSTP
      , VMPEI
      , VMBKL
      , VMSAV
      , VJKUM
      , VJSAL
      , VJVPR
      , VJVER
      , VJSTP
      , VJPEI
      , VJBKL
      , VJSAV
      , LFGJA
      , LFMON
      , BWTTY
      , STPRV
      , LAEPR
      , ZKPRS
      , ZKDAT
      , TIMESTAMP
      , BWPRS
      , BWPRH
      , VJBWS
      , VJBWH
      , VVJSL
      , VVJLB
      , VVMLB
      , VVSAL
      , ZPLPR
      , ZPLP1
      , ZPLP2
      , ZPLP3
      , ZPLD1
      , ZPLD2
      , ZPLD3
      , PPERZ
      , PPERL
      , PPERV
      , KALKZ
      , KALKL
      , KALKV
      , KALSC
      , XLIFO
      , MYPOL
      , BWPH1
      , BWPS1
      , ABWKZ
      , PSTAT
      , KALN1
      , KALNR
      , BWVA1
      , BWVA2
      , BWVA3
      , VERS1
      , VERS2
      , VERS3
      , HRKFT
      , KOSGR
      , PPRDZ
      , PPRDL
      , PPRDV
      , PDATZ
      , PDATL
      , PDATV
      , EKALR
      , VPLPR
      , MLMAA
      , MLAST
      , LPLPR
      , VKSAL
      , HKMAT
      , SPERW
      , KZIWL
      , WLINL
      , ABCIW
      , BWSPA
      , LPLPX
      , VPLPX
      , FPLPX
      , LBWST
      , VBWST
      , FBWST
      , EKLAS
      , QKLAS
      , MTUSE
      , MTORG
      , OWNPR
      , XBEWM
      , BWPEI
      , MBRUE
      , OKLAS
      , OIPPINV
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_FA
)
---- FILTER LAYER ----

, FILTER_FA as (
    SELECT *
    FROM RENAME_FA
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_FA
)

---- FINAL LAYER ----
SELECT
          LNK_MATERIAL_VALUATION_HK
        , MANDT
        , MATNR
        , BWKEY
        , BWTAR
        , LVORM
        , LBKUM
        , SALK3
        , VPRSV
        , VERPR
        , STPRS
        , PEINH
        , BKLAS
        , SALKV
        , VMKUM
        , VMSAL
        , VMVPR
        , VMVER
        , VMSTP
        , VMPEI
        , VMBKL
        , VMSAV
        , VJKUM
        , VJSAL
        , VJVPR
        , VJVER
        , VJSTP
        , VJPEI
        , VJBKL
        , VJSAV
        , LFGJA
        , LFMON
        , BWTTY
        , STPRV
        , LAEPR
        , ZKPRS
        , ZKDAT
        , TIMESTAMP
        , BWPRS
        , BWPRH
        , VJBWS
        , VJBWH
        , VVJSL
        , VVJLB
        , VVMLB
        , VVSAL
        , ZPLPR
        , ZPLP1
        , ZPLP2
        , ZPLP3
        , ZPLD1
        , ZPLD2
        , ZPLD3
        , PPERZ
        , PPERL
        , PPERV
        , KALKZ
        , KALKL
        , KALKV
        , KALSC
        , XLIFO
        , MYPOL
        , BWPH1
        , BWPS1
        , ABWKZ
        , PSTAT
        , KALN1
        , KALNR
        , BWVA1
        , BWVA2
        , BWVA3
        , VERS1
        , VERS2
        , VERS3
        , HRKFT
        , KOSGR
        , PPRDZ
        , PPRDL
        , PPRDV
        , PDATZ
        , PDATL
        , PDATV
        , EKALR
        , VPLPR
        , MLMAA
        , MLAST
        , LPLPR
        , VKSAL
        , HKMAT
        , SPERW
        , KZIWL
        , WLINL
        , ABCIW
        , BWSPA
        , LPLPX
        , VPLPX
        , FPLPX
        , LBWST
        , VBWST
        , FBWST
        , EKLAS
        , QKLAS
        , MTUSE
        , MTORG
        , OWNPR
        , XBEWM
        , BWPEI
        , MBRUE
        , OKLAS
        , OIPPINV
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LNK_MATERIAL_VALUATION_HK= JOIN_RESULT.LNK_MATERIAL_VALUATION_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by LNK_MATERIAL_VALUATION_HK, HASHDIFF order by PSA_LOAD_DTS)
union all
    SELECT        
    MD5_BINARY(GR.VALUE) AS LNK_MATERIAL_VALUATION_HK,
     NULL AS MANDT
, NULL AS MATNR
, NULL AS BWKEY
, NULL AS BWTAR
, NULL AS LVORM
, NULL AS LBKUM
, NULL AS SALK3
, NULL AS VPRSV
, NULL AS VERPR
, NULL AS STPRS
, NULL AS PEINH
, NULL AS BKLAS
, NULL AS SALKV
, NULL AS VMKUM
, NULL AS VMSAL
, NULL AS VMVPR
, NULL AS VMVER
, NULL AS VMSTP
, NULL AS VMPEI
, NULL AS VMBKL
, NULL AS VMSAV
, NULL AS VJKUM
, NULL AS VJSAL
, NULL AS VJVPR
, NULL AS VJVER
, NULL AS VJSTP
, NULL AS VJPEI
, NULL AS VJBKL
, NULL AS VJSAV
, NULL AS LFGJA
, NULL AS LFMON
, NULL AS BWTTY
, NULL AS STPRV
, NULL AS LAEPR
, NULL AS ZKPRS
, NULL AS ZKDAT
, NULL AS TIMESTAMP
, NULL AS BWPRS
, NULL AS BWPRH
, NULL AS VJBWS
, NULL AS VJBWH
, NULL AS VVJSL
, NULL AS VVJLB
, NULL AS VVMLB
, NULL AS VVSAL
, NULL AS ZPLPR
, NULL AS ZPLP1
, NULL AS ZPLP2
, NULL AS ZPLP3
, NULL AS ZPLD1
, NULL AS ZPLD2
, NULL AS ZPLD3
, NULL AS PPERZ
, NULL AS PPERL
, NULL AS PPERV
, NULL AS KALKZ
, NULL AS KALKL
, NULL AS KALKV
, NULL AS KALSC
, NULL AS XLIFO
, NULL AS MYPOL
, NULL AS BWPH1
, NULL AS BWPS1
, NULL AS ABWKZ
, NULL AS PSTAT
, NULL AS KALN1
, NULL AS KALNR
, NULL AS BWVA1
, NULL AS BWVA2
, NULL AS BWVA3
, NULL AS VERS1
, NULL AS VERS2
, NULL AS VERS3
, NULL AS HRKFT
, NULL AS KOSGR
, NULL AS PPRDZ
, NULL AS PPRDL
, NULL AS PPRDV
, NULL AS PDATZ
, NULL AS PDATL
, NULL AS PDATV
, NULL AS EKALR
, NULL AS VPLPR
, NULL AS MLMAA
, NULL AS MLAST
, NULL AS LPLPR
, NULL AS VKSAL
, NULL AS HKMAT
, NULL AS SPERW
, NULL AS KZIWL
, NULL AS WLINL
, NULL AS ABCIW
, NULL AS BWSPA
, NULL AS LPLPX
, NULL AS VPLPX
, NULL AS FPLPX
, NULL AS LBWST
, NULL AS VBWST
, NULL AS FBWST
, NULL AS EKLAS
, NULL AS QKLAS
, NULL AS MTUSE
, NULL AS MTORG
, NULL AS OWNPR
, NULL AS XBEWM
, NULL AS BWPEI
, NULL AS MBRUE
, NULL AS OKLAS
, NULL AS OIPPINV
, NULL AS GLDELFLAG
, NULL AS GLCHANGETIME
, NULL AS GLSOURCESYSTEM
, NULL AS PSA_LOAD_DTS
, NULL AS PSA_RECORD_SOURCE
, NULL AS PSA_DELETE_IND
, CONVERT_TIMEZONE('UTC','1900-01-01')  as  LOAD_DTS
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, ''::BINARY as HASH_DIFF FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}