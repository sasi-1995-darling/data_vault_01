---- SRC LAYER ----
WITH
SRC_SWINN          as ( SELECT * FROM {{ ref('v_psa_stg_cost_center_master_data__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SWINN          as ( SELECT * FROM STAGING.V_PSA_STG_COST_CENTER_MASTER_DATA__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_SWINN as (
    SELECT
        COST_CENTER_MASTER_DATA_HK
      , MANDT
      , KOKRS
      , KOSTL
      , DATBI
      , GLREQUEST
      , DATAB
      , BKZKP
      , PKZKP
      , BUKRS
      , GSBER
      , KOSAR
      , VERAK
      , VERAK_USER
      , WAERS
      , KALSM
      , TXJCD
      , PRCTR
      , WERKS
      , LOGSYSTEM
      , ERSDA
      , USNAM
      , BKZKS
      , BKZER
      , BKZOB
      , PKZKS
      , PKZER
      , VMETH
      , MGEFL
      , ABTEI
      , NKOST
      , KVEWE
      , KAPPL
      , KOSZSCHL
      , LAND1
      , ANRED
      , NAME1
      , NAME2
      , NAME3
      , NAME4
      , ORT01
      , ORT02
      , STRAS
      , PFACH
      , PSTLZ
      , PSTL2
      , REGIO
      , SPRAS
      , TELBX
      , TELF1
      , TELF2
      , TELFX
      , TELTX
      , TELX1
      , DATLT
      , DRNAM
      , KHINR
      , CCKEY
      , KOMPL
      , STAKZ
      , OBJNR
      , FUNKT
      , AFUNK
      , CPI_TEMPL
      , CPD_TEMPL
      , FUNC_AREA
      , SCI_TEMPL
      , SCD_TEMPL
      , SKI_TEMPL
      , SKD_TEMPL
      , ZVKBUR
      , VNAME
      , RECID
      , ETYPE
      , JV_OTYPE
      , JV_JIBCL
      , JV_JIBSA
      , FERC_IND
      , GLDELFLAG
      , GLCHANGETIME
      , GLCHANGETIME_DTTM
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_SWINN
)
---- RENAME LAYER ----

, RENAME_SWINN as (
    SELECT
        COST_CENTER_MASTER_DATA_HK 
      , MANDT
      , KOKRS
      , KOSTL
      , DATBI
      , GLREQUEST
      , DATAB
      , BKZKP
      , PKZKP
      , BUKRS
      , GSBER
      , KOSAR
      , VERAK
      , VERAK_USER
      , WAERS
      , KALSM
      , TXJCD
      , PRCTR
      , WERKS
      , LOGSYSTEM
      , ERSDA
      , USNAM
      , BKZKS
      , BKZER
      , BKZOB
      , PKZKS
      , PKZER
      , VMETH
      , MGEFL
      , ABTEI
      , NKOST
      , KVEWE
      , KAPPL
      , KOSZSCHL
      , LAND1
      , ANRED
      , NAME1
      , NAME2
      , NAME3
      , NAME4
      , ORT01
      , ORT02
      , STRAS
      , PFACH
      , PSTLZ
      , PSTL2
      , REGIO
      , SPRAS
      , TELBX
      , TELF1
      , TELF2
      , TELFX
      , TELTX
      , TELX1
      , DATLT
      , DRNAM
      , KHINR
      , CCKEY
      , KOMPL
      , STAKZ
      , OBJNR
      , FUNKT
      , AFUNK
      , CPI_TEMPL
      , CPD_TEMPL
      , FUNC_AREA
      , SCI_TEMPL
      , SCD_TEMPL
      , SKI_TEMPL
      , SKD_TEMPL
      , ZVKBUR
      , VNAME
      , RECID
      , ETYPE
      , JV_OTYPE
      , JV_JIBCL
      , JV_JIBSA
      , FERC_IND
      , GLDELFLAG
      , GLCHANGETIME
      , GLCHANGETIME_DTTM
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , LOAD_DTS
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
          COST_CENTER_MASTER_DATA_HK 
        , MANDT
        , KOKRS
        , KOSTL
        , DATBI
        , GLREQUEST
        , DATAB
        , BKZKP
        , PKZKP
        , BUKRS
        , GSBER
        , KOSAR
        , VERAK
        , VERAK_USER
        , WAERS
        , KALSM
        , TXJCD
        , PRCTR
        , WERKS
        , LOGSYSTEM
        , ERSDA
        , USNAM
        , BKZKS
        , BKZER
        , BKZOB
        , PKZKS
        , PKZER
        , VMETH
        , MGEFL
        , ABTEI
        , NKOST
        , KVEWE
        , KAPPL
        , KOSZSCHL
        , LAND1
        , ANRED
        , NAME1
        , NAME2
        , NAME3
        , NAME4
        , ORT01
        , ORT02
        , STRAS
        , PFACH
        , PSTLZ
        , PSTL2
        , REGIO
        , SPRAS
        , TELBX
        , TELF1
        , TELF2
        , TELFX
        , TELTX
        , TELX1
        , DATLT
        , DRNAM
        , KHINR
        , CCKEY
        , KOMPL
        , STAKZ
        , OBJNR
        , FUNKT
        , AFUNK
        , CPI_TEMPL
        , CPD_TEMPL
        , FUNC_AREA
        , SCI_TEMPL
        , SCD_TEMPL
        , SKI_TEMPL
        , SKD_TEMPL
        , ZVKBUR
        , VNAME
        , RECID
        , ETYPE
        , JV_OTYPE
        , JV_JIBCL
        , JV_JIBSA
        , FERC_IND
        , GLDELFLAG
        , GLCHANGETIME
        , GLCHANGETIME_DTTM
        , GLSOURCESYSTEM
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
    WHERE existing.COST_CENTER_MASTER_DATA_HK = JOIN_RESULT.COST_CENTER_MASTER_DATA_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by COST_CENTER_MASTER_DATA_HK, HASHDIFF order by LOAD_DTS)
union all
    SELECT        
    MD5_BINARY(GR.VALUE) AS COST_CENTER_MASTER_DATA_HK
, CAST(NULL AS STRING) AS MANDT
, CAST(NULL AS STRING) AS KOKRS
, CAST(NULL AS STRING) AS KOSTL
, CAST(NULL AS STRING) AS DATBI
, CAST(NULL AS STRING) AS GLREQUEST
, CAST(NULL AS STRING) AS DATAB
, CAST(NULL AS STRING) AS BKZKP
, CAST(NULL AS STRING) AS PKZKP
, CAST(NULL AS STRING) AS BUKRS
, CAST(NULL AS STRING) AS GSBER
, CAST(NULL AS STRING) AS KOSAR
, CAST(NULL AS STRING) AS VERAK
, CAST(NULL AS STRING) AS VERAK_USER
, CAST(NULL AS STRING) AS WAERS
, CAST(NULL AS STRING) AS KALSM
, CAST(NULL AS STRING) AS TXJCD
, CAST(NULL AS STRING) AS PRCTR
, CAST(NULL AS STRING) AS WERKS
, CAST(NULL AS STRING) AS LOGSYSTEM
, CAST(NULL AS STRING) AS ERSDA
, CAST(NULL AS STRING) AS USNAM
, CAST(NULL AS STRING) AS BKZKS
, CAST(NULL AS STRING) AS BKZER
, CAST(NULL AS STRING) AS BKZOB
, CAST(NULL AS STRING) AS PKZKS
, CAST(NULL AS STRING) AS PKZER
, CAST(NULL AS STRING) AS VMETH
, CAST(NULL AS STRING) AS MGEFL
, CAST(NULL AS STRING) AS ABTEI
, CAST(NULL AS STRING) AS NKOST
, CAST(NULL AS STRING) AS KVEWE
, CAST(NULL AS STRING) AS KAPPL
, CAST(NULL AS STRING) AS KOSZSCHL
, CAST(NULL AS STRING) AS LAND1
, CAST(NULL AS STRING) AS ANRED
, CAST(NULL AS STRING) AS NAME1
, CAST(NULL AS STRING) AS NAME2
, CAST(NULL AS STRING) AS NAME3
, CAST(NULL AS STRING) AS NAME4
, CAST(NULL AS STRING) AS ORT01
, CAST(NULL AS STRING) AS ORT02
, CAST(NULL AS STRING) AS STRAS
, CAST(NULL AS STRING) AS PFACH
, CAST(NULL AS STRING) AS PSTLZ
, CAST(NULL AS STRING) AS PSTL2
, CAST(NULL AS STRING) AS REGIO
, CAST(NULL AS STRING) AS SPRAS
, CAST(NULL AS STRING) AS TELBX
, CAST(NULL AS STRING) AS TELF1
, CAST(NULL AS STRING) AS TELF2
, CAST(NULL AS STRING) AS TELFX
, CAST(NULL AS STRING) AS TELTX
, CAST(NULL AS STRING) AS TELX1
, CAST(NULL AS STRING) AS DATLT
, CAST(NULL AS STRING) AS DRNAM
, CAST(NULL AS STRING) AS KHINR
, CAST(NULL AS STRING) AS CCKEY
, CAST(NULL AS STRING) AS KOMPL
, CAST(NULL AS STRING) AS STAKZ
, CAST(NULL AS STRING) AS OBJNR
, CAST(NULL AS STRING) AS FUNKT
, CAST(NULL AS STRING) AS AFUNK
, CAST(NULL AS STRING) AS CPI_TEMPL
, CAST(NULL AS STRING) AS CPD_TEMPL
, CAST(NULL AS STRING) AS FUNC_AREA
, CAST(NULL AS STRING) AS SCI_TEMPL
, CAST(NULL AS STRING) AS SCD_TEMPL
, CAST(NULL AS STRING) AS SKI_TEMPL
, CAST(NULL AS STRING) AS SKD_TEMPL
, CAST(NULL AS STRING) AS ZVKBUR
, CAST(NULL AS STRING) AS VNAME
, CAST(NULL AS STRING) AS RECID
, CAST(NULL AS STRING) AS ETYPE
, CAST(NULL AS STRING) AS JV_OTYPE
, CAST(NULL AS STRING) AS JV_JIBCL
, CAST(NULL AS STRING) AS JV_JIBSA
, CAST(NULL AS STRING) AS FERC_IND
, CAST(NULL AS STRING) AS GLDELFLAG
, CAST(NULL AS NUMBER) AS GLCHANGETIME
, CAST(NULL AS TIMESTAMP) AS GLCHANGETIME_DTTM
, CAST(NULL AS STRING) AS GLSOURCESYSTEM
, CAST(NULL AS STRING) AS PSA_DELETE_IND
, CONVERT_TIMEZONE('UTC','1900-01-01')  as  LOAD_DTS
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, ''::BINARY as HASHDIFF FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}