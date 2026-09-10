---- SRC LAYER ----
WITH
SRC_STG            as ( SELECT * FROM {{ ref('v_psa_stg_cost_transaction_type__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_STG            as ( SELECT * FROM STAGING.v_psa_stg_business_transactions__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_STG as (
    SELECT
        COST_TRANSACTION_TYPE_HK
      , VRGNG
      , GLREQUEST
      , VRGSV
      , ANWST
      , PRVRG
      , VRGJV
      , VRGCO
      , NVVRG
      , PERSP
      , PSIKZ
      , WTKAT
      , ACTGRP
      , SUBGRP
      , XCOEP
      , XCOEJ
      , XCOOI
      , XCOSP
      , XCOSS
      , XCOEPL
      , XCOEJL
      , XCOEPR
      , XCOEJR
      , XCOEPT
      , XCOEJT
      , XCOEPB
      , XCOFP
      , XFMGM
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
        COST_TRANSACTION_TYPE_HK
      , VRGNG
      , GLREQUEST
      , VRGSV
      , ANWST
      , PRVRG
      , VRGJV
      , VRGCO
      , NVVRG
      , PERSP
      , PSIKZ
      , WTKAT
      , ACTGRP
      , SUBGRP
      , XCOEP
      , XCOEJ
      , XCOOI
      , XCOSP
      , XCOSS
      , XCOEPL
      , XCOEJL
      , XCOEPR
      , XCOEJR
      , XCOEPT
      , XCOEJT
      , XCOEPB
      , XCOFP
      , XFMGM
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
          COST_TRANSACTION_TYPE_HK
        , VRGNG
        , GLREQUEST
        , VRGSV
        , ANWST
        , PRVRG
        , VRGJV
        , VRGCO
        , NVVRG
        , PERSP
        , PSIKZ
        , WTKAT
        , ACTGRP
        , SUBGRP
        , XCOEP
        , XCOEJ
        , XCOOI
        , XCOSP
        , XCOSS
        , XCOEPL
        , XCOEJL
        , XCOEPR
        , XCOEJR
        , XCOEPT
        , XCOEJT
        , XCOEPB
        , XCOFP
        , XFMGM
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
    WHERE existing.COST_TRANSACTION_TYPE_HK= JOIN_RESULT.COST_TRANSACTION_TYPE_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by COST_TRANSACTION_TYPE_HK, HASHDIFF order by PSA_LOAD_DTS)
union all
    SELECT        
    MD5_BINARY(GR.VALUE) AS COST_TRANSACTION_TYPE_HK,
     NULL AS VRGNG
, NULL AS GLREQUEST
, NULL AS VRGSV
, NULL AS ANWST
, NULL AS PRVRG
, NULL AS VRGJV
, NULL AS VRGCO
, NULL AS NVVRG
, NULL AS PERSP
, NULL AS PSIKZ
, NULL AS WTKAT
, NULL AS ACTGRP
, NULL AS SUBGRP
, NULL AS XCOEP
, NULL AS XCOEJ
, NULL AS XCOOI
, NULL AS XCOSP
, NULL AS XCOSS
, NULL AS XCOEPL
, NULL AS XCOEJL
, NULL AS XCOEPR
, NULL AS XCOEJR
, NULL AS XCOEPT
, NULL AS XCOEJT
, NULL AS XCOEPB
, NULL AS XCOFP
, NULL AS XFMGM
, NULL AS GLDELFLAG
, NULL AS GLSOURCESYSTEM
, NULL AS GLCHANGETIME
, NULL AS PSA_LOAD_DTS
, NULL AS PSA_RECORD_SOURCE
, NULL AS PSA_DELETE_IND
, CONVERT_TIMEZONE('UTC','1900-01-01')  as  LOAD_DTS
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, ''::BINARY as HASH_DIFF FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}