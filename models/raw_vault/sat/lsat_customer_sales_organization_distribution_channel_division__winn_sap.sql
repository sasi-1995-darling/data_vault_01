---- SRC LAYER ----
WITH
SRC_SCSMWS         as ( SELECT * FROM {{ ref('v_psa_stg_customer_sales_master__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %} )

/*
SRC_SCSMWS         as ( SELECT * FROM STAGING.v_psa_stg_customer_sales_master__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_SCSMWS as (
    SELECT
        LNK_CUSTOMER_SALES_ORGANIZATION_DISTRIBUTION_CHANNEL_DIVISION_HK
      , MANDT
      , KUNNR
      , VKORG
      , VTWEG
      , SPART
      , GLREQUEST
      , ERNAM
      , ERDAT
      , BEGRU
      , LOEVM
      , VERSG
      , AUFSD
      , KALKS
      , KDGRP
      , BZIRK
      , KONDA
      , PLTYP
      , AWAHR
      , INCO1
      , INCO2
      , LIFSD
      , AUTLF
      , ANTLF
      , KZTLF
      , KZAZU
      , CHSPL
      , LPRIO
      , EIKTO
      , VSBED
      , FAKSD
      , MRNKZ
      , PERFK
      , PERRL
      , KVAKZ
      , KVAWT
      , WAERS
      , KLABC
      , KTGRD
      , ZTERM
      , VWERK
      , VKGRP
      , VKBUR
      , VSORT
      , KVGR1
      , KVGR2
      , KVGR3
      , KVGR4
      , KVGR5
      , BOKRE
      , BOIDT
      , KURST
      , PRFRE
      , PRAT1
      , PRAT2
      , PRAT3
      , PRAT4
      , PRAT5
      , PRAT6
      , PRAT7
      , PRAT8
      , PRAT9
      , PRATA
      , KABSS
      , KKBER
      , CASSD
      , RDOFF
      , AGREL
      , MEGRU
      , UEBTO
      , UNTTO
      , UEBTK
      , PVKSM
      , PODKZ
      , PODTG
      , BLIND
      , CARRIER_NOTIF
      , CVP_XBLCK_V
      , INCOV
      , INCO2_L
      , INCO3_L
      , BEV1_EMLGPFAND
      , BEV1_EMLGFORTS
      , FSH_KVGR6
      , FSH_KVGR7
      , FSH_KVGR8
      , FSH_KVGR9
      , FSH_KVGR10
      , FSH_GRREG
      , FSH_RESGY
      , FSH_SC_CID
      , FSH_VAS_DETC
      , FSH_VAS_CG
      , FSH_GRSGY
      , FSH_SS
      , FSH_MSOCDC
      , FSH_MSOPID
      , ZOLD_CUSTOMER
      , ZZTEA
      , ZZBRSCH
      , ZZKATR1
      , ZZKATR2
      , ZZKATR3
      , ZZGROUP_APO
      , ZZAPO_PRICE_ACCT
      , ZZSNGOR
      , ZZSHWOR
      , ZZW2B
      , ZZSOD
      , ZZACCT
      , ZZACCTNAME
      , ZZCMBDELVINV
      , ZZTAXABLE
      , ZZCID
      , ZZTMS
      , ZZCONSOLIDATE
      , ZZTMSEXE
      , ZZBPEXC
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_SCSMWS
)
---- RENAME LAYER ----

, RENAME_SCSMWS as (
    SELECT
        LNK_CUSTOMER_SALES_ORGANIZATION_DISTRIBUTION_CHANNEL_DIVISION_HK
      , MANDT
      , KUNNR
      , VKORG
      , VTWEG
      , SPART
      , GLREQUEST
      , ERNAM
      , ERDAT
      , BEGRU
      , LOEVM
      , VERSG
      , AUFSD
      , KALKS
      , KDGRP
      , BZIRK
      , KONDA
      , PLTYP
      , AWAHR
      , INCO1
      , INCO2
      , LIFSD
      , AUTLF
      , ANTLF
      , KZTLF
      , KZAZU
      , CHSPL
      , LPRIO
      , EIKTO
      , VSBED
      , FAKSD
      , MRNKZ
      , PERFK
      , PERRL
      , KVAKZ
      , KVAWT
      , WAERS
      , KLABC
      , KTGRD
      , ZTERM
      , VWERK
      , VKGRP
      , VKBUR
      , VSORT
      , KVGR1
      , KVGR2
      , KVGR3
      , KVGR4
      , KVGR5
      , BOKRE
      , BOIDT
      , KURST
      , PRFRE
      , PRAT1
      , PRAT2
      , PRAT3
      , PRAT4
      , PRAT5
      , PRAT6
      , PRAT7
      , PRAT8
      , PRAT9
      , PRATA
      , KABSS
      , KKBER
      , CASSD
      , RDOFF
      , AGREL
      , MEGRU
      , UEBTO
      , UNTTO
      , UEBTK
      , PVKSM
      , PODKZ
      , PODTG
      , BLIND
      , CARRIER_NOTIF
      , CVP_XBLCK_V
      , INCOV
      , INCO2_L
      , INCO3_L
      , BEV1_EMLGPFAND
      , BEV1_EMLGFORTS
      , FSH_KVGR6
      , FSH_KVGR7
      , FSH_KVGR8
      , FSH_KVGR9
      , FSH_KVGR10
      , FSH_GRREG
      , FSH_RESGY
      , FSH_SC_CID
      , FSH_VAS_DETC
      , FSH_VAS_CG
      , FSH_GRSGY
      , FSH_SS
      , FSH_MSOCDC
      , FSH_MSOPID
      , ZOLD_CUSTOMER
      , ZZTEA
      , ZZBRSCH
      , ZZKATR1
      , ZZKATR2
      , ZZKATR3
      , ZZGROUP_APO
      , ZZAPO_PRICE_ACCT
      , ZZSNGOR
      , ZZSHWOR
      , ZZW2B
      , ZZSOD
      , ZZACCT
      , ZZACCTNAME
      , ZZCMBDELVINV
      , ZZTAXABLE
      , ZZCID
      , ZZTMS
      , ZZCONSOLIDATE
      , ZZTMSEXE
      , ZZBPEXC
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_SCSMWS
)
---- FILTER LAYER ----

, FILTER_SCSMWS as (
    SELECT *
    FROM RENAME_SCSMWS
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SCSMWS
)

---- FINAL LAYER ----
SELECT
          LNK_CUSTOMER_SALES_ORGANIZATION_DISTRIBUTION_CHANNEL_DIVISION_HK
        , MANDT
        , KUNNR
        , VKORG
        , VTWEG
        , SPART
        , GLREQUEST
        , ERNAM
        , ERDAT
        , BEGRU
        , LOEVM
        , VERSG
        , AUFSD
        , KALKS
        , KDGRP
        , BZIRK
        , KONDA
        , PLTYP
        , AWAHR
        , INCO1
        , INCO2
        , LIFSD
        , AUTLF
        , ANTLF
        , KZTLF
        , KZAZU
        , CHSPL
        , LPRIO
        , EIKTO
        , VSBED
        , FAKSD
        , MRNKZ
        , PERFK
        , PERRL
        , KVAKZ
        , KVAWT
        , WAERS
        , KLABC
        , KTGRD
        , ZTERM
        , VWERK
        , VKGRP
        , VKBUR
        , VSORT
        , KVGR1
        , KVGR2
        , KVGR3
        , KVGR4
        , KVGR5
        , BOKRE
        , BOIDT
        , KURST
        , PRFRE
        , PRAT1
        , PRAT2
        , PRAT3
        , PRAT4
        , PRAT5
        , PRAT6
        , PRAT7
        , PRAT8
        , PRAT9
        , PRATA
        , KABSS
        , KKBER
        , CASSD
        , RDOFF
        , AGREL
        , MEGRU
        , UEBTO
        , UNTTO
        , UEBTK
        , PVKSM
        , PODKZ
        , PODTG
        , BLIND
        , CARRIER_NOTIF
        , CVP_XBLCK_V
        , INCOV
        , INCO2_L
        , INCO3_L
        , BEV1_EMLGPFAND
        , BEV1_EMLGFORTS
        , FSH_KVGR6
        , FSH_KVGR7
        , FSH_KVGR8
        , FSH_KVGR9
        , FSH_KVGR10
        , FSH_GRREG
        , FSH_RESGY
        , FSH_SC_CID
        , FSH_VAS_DETC
        , FSH_VAS_CG
        , FSH_GRSGY
        , FSH_SS
        , FSH_MSOCDC
        , FSH_MSOPID
        , ZOLD_CUSTOMER
        , ZZTEA
        , ZZBRSCH
        , ZZKATR1
        , ZZKATR2
        , ZZKATR3
        , ZZGROUP_APO
        , ZZAPO_PRICE_ACCT
        , ZZSNGOR
        , ZZSHWOR
        , ZZW2B
        , ZZSOD
        , ZZACCT
        , ZZACCTNAME
        , ZZCMBDELVINV
        , ZZTAXABLE
        , ZZCID
        , ZZTMS
        , ZZCONSOLIDATE
        , ZZTMSEXE
        , ZZBPEXC
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LNK_CUSTOMER_SALES_ORGANIZATION_DISTRIBUTION_CHANNEL_DIVISION_HK = JOIN_RESULT.LNK_CUSTOMER_SALES_ORGANIZATION_DISTRIBUTION_CHANNEL_DIVISION_HK
	AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by LNK_CUSTOMER_SALES_ORGANIZATION_DISTRIBUTION_CHANNEL_DIVISION_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS LNK_CUSTOMER_SALES_ORGANIZATION_DISTRIBUTION_CHANNEL_DIVISION_HK,
NULL AS MANDT,
GR.VALUE::text AS KUNNR,
GR.VALUE::text AS VKORG,
GR.VALUE::text AS VTWEG,
GR.VALUE::text AS SPART,
NULL AS GLREQUEST,
NULL AS ERNAM,
NULL AS ERDAT,
NULL AS BEGRU,
NULL AS LOEVM,
NULL AS VERSG,
NULL AS AUFSD,
NULL AS KALKS,
NULL AS KDGRP,
NULL AS BZIRK,
NULL AS KONDA,
NULL AS PLTYP,
NULL AS AWAHR,
NULL AS INCO1,
NULL AS INCO2,
NULL AS LIFSD,
NULL AS AUTLF,
NULL AS ANTLF,
NULL AS KZTLF,
NULL AS KZAZU,
NULL AS CHSPL,
NULL AS LPRIO,
NULL AS EIKTO,
NULL AS VSBED,
NULL AS FAKSD,
NULL AS MRNKZ,
NULL AS PERFK,
NULL AS PERRL,
NULL AS KVAKZ,
NULL AS KVAWT,
NULL AS WAERS,
NULL AS KLABC,
NULL AS KTGRD,
NULL AS ZTERM,
NULL AS VWERK,
NULL AS VKGRP,
NULL AS VKBUR,
NULL AS VSORT,
NULL AS KVGR1,
NULL AS KVGR2,
NULL AS KVGR3,
NULL AS KVGR4,
NULL AS KVGR5,
NULL AS BOKRE,
NULL AS BOIDT,
NULL AS KURST,
NULL AS PRFRE,
NULL AS PRAT1,
NULL AS PRAT2,
NULL AS PRAT3,
NULL AS PRAT4,
NULL AS PRAT5,
NULL AS PRAT6,
NULL AS PRAT7,
NULL AS PRAT8,
NULL AS PRAT9,
NULL AS PRATA,
NULL AS KABSS,
NULL AS KKBER,
NULL AS CASSD,
NULL AS RDOFF,
NULL AS AGREL,
NULL AS MEGRU,
NULL AS UEBTO,
NULL AS UNTTO,
NULL AS UEBTK,
NULL AS PVKSM,
NULL AS PODKZ,
NULL AS PODTG,
NULL AS BLIND,
NULL AS CARRIER_NOTIF,
NULL AS CVP_XBLCK_V,
NULL AS INCOV,
NULL AS INCO2_L,
NULL AS INCO3_L,
NULL AS BEV1_EMLGPFAND,
NULL AS BEV1_EMLGFORTS,
NULL AS FSH_KVGR6,
NULL AS FSH_KVGR7,
NULL AS FSH_KVGR8,
NULL AS FSH_KVGR9,
NULL AS FSH_KVGR10,
NULL AS FSH_GRREG,
NULL AS FSH_RESGY,
NULL AS FSH_SC_CID,
NULL AS FSH_VAS_DETC,
NULL AS FSH_VAS_CG,
NULL AS FSH_GRSGY,
NULL AS FSH_SS,
NULL AS FSH_MSOCDC,
NULL AS FSH_MSOPID,
NULL AS ZOLD_CUSTOMER,
NULL AS ZZTEA,
NULL AS ZZBRSCH,
NULL AS ZZKATR1,
NULL AS ZZKATR2,
NULL AS ZZKATR3,
NULL AS ZZGROUP_APO,
NULL AS ZZAPO_PRICE_ACCT,
NULL AS ZZSNGOR,
NULL AS ZZSHWOR,
NULL AS ZZW2B,
NULL AS ZZSOD,
NULL AS ZZACCT,
NULL AS ZZACCTNAME,
NULL AS ZZCMBDELVINV,
NULL AS ZZTAXABLE,
NULL AS ZZCID,
NULL AS ZZTMS,
NULL AS ZZCONSOLIDATE,
NULL AS ZZTMSEXE,
NULL AS ZZBPEXC,
NULL AS GLDELFLAG,
NULL AS GLCHANGETIME,
NULL AS GLSOURCESYSTEM,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
