---- SRC LAYER ----
WITH
SRC_SWINN          as ( SELECT * FROM {{ ref('v_psa_stg_profit_center_master_data__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SWINN          as ( SELECT * FROM STAGING.v_psa_stg_profit_center_master_data__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_SWINN as (
    SELECT
        OBJECT_NUMBER_HK
      , MANDT
      , PRCTR
      , DATBI
      , KOKRS
      , GLREQUEST
      , DATAB
      , ERSDA
      , USNAM
      , MERKMAL
      , ABTEI
      , VERAK
      , VERAK_USER
      , WAERS
      , NPRCTR
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
      , BUKRS
      , VNAME
      , RECID
      , ETYPE
      , TXJCD
      , REGIO
      , KVEWE
      , KAPPL
      , KALSM
      , LOGSYSTEM
      , LOCK_IND
      , PCA_TEMPLATE
      , SEGMENT
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
    FROM SRC_SWINN
)
---- RENAME LAYER ----

, RENAME_SWINN as (
    SELECT
        OBJECT_NUMBER_HK
      , MANDT
      , PRCTR
      , DATBI
      , KOKRS
      , GLREQUEST
      , DATAB
      , ERSDA
      , USNAM
      , MERKMAL
      , ABTEI
      , VERAK
      , VERAK_USER
      , WAERS
      , NPRCTR
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
      , BUKRS
      , VNAME
      , RECID
      , ETYPE
      , TXJCD
      , REGIO
      , KVEWE
      , KAPPL
      , KALSM
      , LOGSYSTEM
      , LOCK_IND
      , PCA_TEMPLATE
      , SEGMENT
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
          OBJECT_NUMBER_HK
        , MANDT
        , PRCTR
        , DATBI
        , KOKRS
        , GLREQUEST
        , DATAB
        , ERSDA
        , USNAM
        , MERKMAL
        , ABTEI
        , VERAK
        , VERAK_USER
        , WAERS
        , NPRCTR
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
        , BUKRS
        , VNAME
        , RECID
        , ETYPE
        , TXJCD
        , REGIO
        , KVEWE
        , KAPPL
        , KALSM
        , LOGSYSTEM
        , LOCK_IND
        , PCA_TEMPLATE
        , SEGMENT
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
    WHERE existing.OBJECT_NUMBER_HK= JOIN_RESULT.OBJECT_NUMBER_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by OBJECT_NUMBER_HK, HASHDIFF order by PSA_LOAD_DTS desc)
union all
    SELECT        
    MD5_BINARY(GR.VALUE) AS OBJECT_NUMBER_HK
, NULL AS MANDT
, NULL AS PRCTR
, NULL AS DATBI
, NULL AS KOKRS
, NULL AS GLREQUEST
, NULL AS DATAB
, NULL AS ERSDA
, NULL AS USNAM
, NULL AS MERKMAL
, NULL AS ABTEI
, NULL AS VERAK
, NULL AS VERAK_USER
, NULL AS WAERS
, NULL AS NPRCTR
, NULL AS LAND1
, NULL AS ANRED
, NULL AS NAME1
, NULL AS NAME2
, NULL AS NAME3
, NULL AS NAME4
, NULL AS ORT01
, NULL AS ORT02
, NULL AS STRAS
, NULL AS PFACH
, NULL AS PSTLZ
, NULL AS PSTL2
, NULL AS SPRAS
, NULL AS TELBX
, NULL AS TELF1
, NULL AS TELF2
, NULL AS TELFX
, NULL AS TELTX
, NULL AS TELX1
, NULL AS DATLT
, NULL AS DRNAM
, NULL AS KHINR
, NULL AS BUKRS
, NULL AS VNAME
, NULL AS RECID
, NULL AS ETYPE
, NULL AS TXJCD
, NULL AS REGIO
, NULL AS KVEWE
, NULL AS KAPPL
, NULL AS KALSM
, NULL AS LOGSYSTEM
, NULL AS LOCK_IND
, NULL AS PCA_TEMPLATE
, NULL AS SEGMENT
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