---- SRC LAYER ----
WITH
SRC_SWINN          as ( SELECT * FROM {{ ref('v_psa_stg_statistical_key_figure_totals__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SWINN          as ( SELECT * FROM STAGING.v_psa_stg_statistical_key_figure_totals__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_SWINN as (
    SELECT
        STATISTICAL_KEY_FIGURE_TOTALS_HK
      , MANDT
      , LEDNR
      , OBJNR
      , GJAHR
      , WRTTP
      , VERSN
      , STAGR
      , HRKFT
      , VRGNG
      , PERBL
      , GLREQUEST
      , MEINH
      , SME001
      , SME002
      , SME003
      , SME004
      , SME005
      , SME006
      , SME007
      , SME008
      , SME009
      , SME010
      , SME011
      , SME012
      , SME013
      , SME014
      , SME015
      , SME016
      , SMA001
      , SMA002
      , SMA003
      , SMA004
      , SMA005
      , SMA006
      , SMA007
      , SMA008
      , SMA009
      , SMA010
      , SMA011
      , SMA012
      , SMA013
      , SMA014
      , SMA015
      , SMA016
      , FKBER
      , SEGMENT
      , GEBER
      , GRANT_NBR
      , BUDGET_PD
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
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
        STATISTICAL_KEY_FIGURE_TOTALS_HK
      , MANDT
      , LEDNR
      , OBJNR
      , GJAHR
      , WRTTP
      , VERSN
      , STAGR
      , HRKFT
      , VRGNG
      , PERBL
      , GLREQUEST
      , MEINH
      , SME001
      , SME002
      , SME003
      , SME004
      , SME005
      , SME006
      , SME007
      , SME008
      , SME009
      , SME010
      , SME011
      , SME012
      , SME013
      , SME014
      , SME015
      , SME016
      , SMA001
      , SMA002
      , SMA003
      , SMA004
      , SMA005
      , SMA006
      , SMA007
      , SMA008
      , SMA009
      , SMA010
      , SMA011
      , SMA012
      , SMA013
      , SMA014
      , SMA015
      , SMA016
      , FKBER
      , SEGMENT
      , GEBER
      , GRANT_NBR
      , BUDGET_PD
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
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
          STATISTICAL_KEY_FIGURE_TOTALS_HK
        , MANDT
        , LEDNR
        , OBJNR
        , GJAHR
        , WRTTP
        , VERSN
        , STAGR
        , HRKFT
        , VRGNG
        , PERBL
        , GLREQUEST
        , MEINH
        , SME001
        , SME002
        , SME003
        , SME004
        , SME005
        , SME006
        , SME007
        , SME008
        , SME009
        , SME010
        , SME011
        , SME012
        , SME013
        , SME014
        , SME015
        , SME016
        , SMA001
        , SMA002
        , SMA003
        , SMA004
        , SMA005
        , SMA006
        , SMA007
        , SMA008
        , SMA009
        , SMA010
        , SMA011
        , SMA012
        , SMA013
        , SMA014
        , SMA015
        , SMA016
        , FKBER
        , SEGMENT
        , GEBER
        , GRANT_NBR
        , BUDGET_PD
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
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
    WHERE existing.STATISTICAL_KEY_FIGURE_TOTALS_HK= JOIN_RESULT.STATISTICAL_KEY_FIGURE_TOTALS_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by STATISTICAL_KEY_FIGURE_TOTALS_HK, HASHDIFF order by PSA_LOAD_DTS)
union all
    SELECT        
    MD5_BINARY(GR.VALUE) AS STATISTICAL_KEY_FIGURE_TOTALS_HK
   , NULL AS MANDT
, NULL AS LEDNR
, NULL AS OBJNR
, NULL AS GJAHR
, NULL AS WRTTP
, NULL AS VERSN
, NULL AS STAGR
, NULL AS HRKFT
, NULL AS VRGNG
, NULL AS PERBL
, NULL AS GLREQUEST
, NULL AS MEINH
, NULL AS SME001
, NULL AS SME002
, NULL AS SME003
, NULL AS SME004
, NULL AS SME005
, NULL AS SME006
, NULL AS SME007
, NULL AS SME008
, NULL AS SME009
, NULL AS SME010
, NULL AS SME011
, NULL AS SME012
, NULL AS SME013
, NULL AS SME014
, NULL AS SME015
, NULL AS SME016
, NULL AS SMA001
, NULL AS SMA002
, NULL AS SMA003
, NULL AS SMA004
, NULL AS SMA005
, NULL AS SMA006
, NULL AS SMA007
, NULL AS SMA008
, NULL AS SMA009
, NULL AS SMA010
, NULL AS SMA011
, NULL AS SMA012
, NULL AS SMA013
, NULL AS SMA014
, NULL AS SMA015
, NULL AS SMA016
, NULL AS FKBER
, NULL AS SEGMENT
, NULL AS GEBER
, NULL AS GRANT_NBR
, NULL AS BUDGET_PD
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