---- SRC LAYER ----
WITH
SRC_STG            as ( SELECT * FROM {{ ref('v_psa_stg_controlling_header__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_STG            as ( SELECT * FROM STAGING.v_psa_stg_controlling_header__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_STG as (
    SELECT
        CONTROLLING_HEADER_HK
      , MANDT
      , KOKRS
      , BELNR
      , GLREQUEST
      , GJAHR
      , VERSN
      , VRGNG
      , TIMESTMP
      , PERAB
      , PERBI
      , BLDAT
      , BUDAT
      , CPUDT
      , USNAM
      , BLTXT
      , STFLG
      , STOKZ
      , REFBT
      , REFBN
      , REFBK
      , REFGJ
      , BLART
      , ORGVG
      , SUMBZ
      , DELBZ
      , WSDAT
      , KURST
      , VARNR
      , KWAER
      , CTYP1
      , CTYP2
      , CTYP3
      , CTYP4
      , AWTYP
      , AWORG
      , LOGSYSTEM
      , CPUTM
      , ALEBZ
      , ALEBN
      , AWSYS
      , AWREF_REV
      , AWORG_REV
      , VALDT
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
    FROM SRC_STG
)
---- RENAME LAYER ----

, RENAME_STG as (
    SELECT
        CONTROLLING_HEADER_HK
      , MANDT
      , KOKRS
      , BELNR
      , GLREQUEST
      , GJAHR
      , VERSN
      , VRGNG
      , TIMESTMP
      , PERAB
      , PERBI
      , BLDAT
      , BUDAT
      , CPUDT
      , USNAM
      , BLTXT
      , STFLG
      , STOKZ
      , REFBT
      , REFBN
      , REFBK
      , REFGJ
      , BLART
      , ORGVG
      , SUMBZ
      , DELBZ
      , WSDAT
      , KURST
      , VARNR
      , KWAER
      , CTYP1
      , CTYP2
      , CTYP3
      , CTYP4
      , AWTYP
      , AWORG
      , LOGSYSTEM
      , CPUTM
      , ALEBZ
      , ALEBN
      , AWSYS
      , AWREF_REV
      , AWORG_REV
      , VALDT
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
    FROM LOGIC_STG
)
---- FILTER LAYER ----

, FILTER_STG as (
    SELECT *
    FROM RENAME_STG
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_STG
)

---- FINAL LAYER ----
SELECT
          CONTROLLING_HEADER_HK
      , MANDT
      , KOKRS
      , BELNR
      , GLREQUEST
      , GJAHR
      , VERSN
      , VRGNG
      , TIMESTMP
      , PERAB
      , PERBI
      , BLDAT
      , BUDAT
      , CPUDT
      , USNAM
      , BLTXT
      , STFLG
      , STOKZ
      , REFBT
      , REFBN
      , REFBK
      , REFGJ
      , BLART
      , ORGVG
      , SUMBZ
      , DELBZ
      , WSDAT
      , KURST
      , VARNR
      , KWAER
      , CTYP1
      , CTYP2
      , CTYP3
      , CTYP4
      , AWTYP
      , AWORG
      , LOGSYSTEM
      , CPUTM
      , ALEBZ
      , ALEBN
      , AWSYS
      , AWREF_REV
      , AWORG_REV
      , VALDT
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
    WHERE existing.CONTROLLING_HEADER_HK= JOIN_RESULT.CONTROLLING_HEADER_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by CONTROLLING_HEADER_HK, HASHDIFF order by PSA_LOAD_DTS)
union all
    SELECT        
    MD5_BINARY(GR.VALUE) AS CONTROLLING_HEADER_HK,
     NULL AS MANDT
, NULL AS KOKRS
, NULL AS BELNR
, NULL AS GLREQUEST
, NULL AS GJAHR
, NULL AS VERSN
, NULL AS VRGNG
, NULL AS TIMESTMP
, NULL AS PERAB
, NULL AS PERBI
, NULL AS BLDAT
, NULL AS BUDAT
, NULL AS CPUDT
, NULL AS USNAM
, NULL AS BLTXT
, NULL AS STFLG
, NULL AS STOKZ
, NULL AS REFBT
, NULL AS REFBN
, NULL AS REFBK
, NULL AS REFGJ
, NULL AS BLART
, NULL AS ORGVG
, NULL AS SUMBZ
, NULL AS DELBZ
, NULL AS WSDAT
, NULL AS KURST
, NULL AS VARNR
, NULL AS KWAER
, NULL AS CTYP1
, NULL AS CTYP2
, NULL AS CTYP3
, NULL AS CTYP4
, NULL AS AWTYP
, NULL AS AWORG
, NULL AS LOGSYSTEM
, NULL AS CPUTM
, NULL AS ALEBZ
, NULL AS ALEBN
, NULL AS AWSYS
, NULL AS AWREF_REV
, NULL AS AWORG_REV
, NULL AS VALDT
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