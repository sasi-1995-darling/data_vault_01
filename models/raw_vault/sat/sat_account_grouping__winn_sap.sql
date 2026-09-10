---- SRC LAYER ----
WITH
SRC_FA             as ( SELECT * FROM {{ ref('v_psa_stg_account_grouping__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_FA             as ( SELECT * FROM STAGING.v_psa_stg_functional_area__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_FA as (
    SELECT
        FUNCTIONAL_AREA_HK
      , MANDT
      , FKBER
      , GLREQUEST
      , AUTHGRP
      , STR_ID
      , FNSUB1
      , FNSUB2
      , FNSUB3
      , CREATED_BY
      , CREATED_ON
      , CREATED_AT
      , MODIFIED_BY
      , MODIFIED_ON
      , MODIFIED_AT
      , DATAB
      , DATBIS
      , DATE_EXP
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
        FUNCTIONAL_AREA_HK
      , MANDT
      , FKBER
      , GLREQUEST
      , AUTHGRP
      , STR_ID
      , FNSUB1
      , FNSUB2
      , FNSUB3
      , CREATED_BY
      , CREATED_ON
      , CREATED_AT
      , MODIFIED_BY
      , MODIFIED_ON
      , MODIFIED_AT
      , DATAB
      , DATBIS
      , DATE_EXP
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
          FUNCTIONAL_AREA_HK
        , MANDT
        , FKBER
        , GLREQUEST
        , AUTHGRP
        , STR_ID
        , FNSUB1
        , FNSUB2
        , FNSUB3
        , CREATED_BY
        , CREATED_ON
        , CREATED_AT
        , MODIFIED_BY
        , MODIFIED_ON
        , MODIFIED_AT
        , DATAB
        , DATBIS
        , DATE_EXP
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
    WHERE existing.FUNCTIONAL_AREA_HK= JOIN_RESULT.FUNCTIONAL_AREA_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by FUNCTIONAL_AREA_HK, HASHDIFF order by PSA_LOAD_DTS)
union all
    SELECT        
    MD5_BINARY(GR.VALUE) AS LEDGER_HK,
     NULL AS MANDT
, NULL AS FKBER
, NULL AS GLREQUEST
, NULL AS AUTHGRP
, NULL AS STR_ID
, NULL AS FNSUB1
, NULL AS FNSUB2
, NULL AS FNSUB3
, NULL AS CREATED_BY
, NULL AS CREATED_ON
, NULL AS CREATED_AT
, NULL AS MODIFIED_BY
, NULL AS MODIFIED_ON
, NULL AS MODIFIED_AT
, NULL AS DATAB
, NULL AS DATBIS
, NULL AS DATE_EXP
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