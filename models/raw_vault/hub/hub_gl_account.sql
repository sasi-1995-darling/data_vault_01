---- SRC LAYER ----
WITH
SRC_SWINN          as ( SELECT GL_ACCOUNT_HK, GL_ACCOUNT_NUMBER_BK, BKCC, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_gl_account__winn_sap') }} as SRC)

/*
SRC_SWINN          as ( SELECT * FROM STAGING.V_PSA_STG_GL_ACCOUNT__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_SWINN as (
    SELECT
        GL_ACCOUNT_HK
      , GL_ACCOUNT_NUMBER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SWINN
)
---- RENAME LAYER ----

, RENAME_SWINN as (
    SELECT
        GL_ACCOUNT_HK
      , GL_ACCOUNT_NUMBER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SWINN
)
---- FILTER LAYER ----

, FILTER_SWINN as (
    SELECT *
    FROM RENAME_SWINN
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_SWINN
)

---- FINAL LAYER ----
SELECT
          GL_ACCOUNT_HK
        , GL_ACCOUNT_NUMBER_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
  WHERE NOT EXISTS (
      SELECT 1 
      FROM {{ this }} existing
      WHERE existing.GL_ACCOUNT_HK = JOIN_RESULT.GL_ACCOUNT_HK
)
{% endif %}
qualify 1 = row_number() over (partition by GL_ACCOUNT_NUMBER_BK,BKCC order by LOAD_DTS)
{% if not is_incremental() %}
union all

SELECT MD5_BINARY(GR.VALUE) GL_ACCOUNT_HK
, GR.VALUE::text AS GL_ACCOUNT_NUMBER_BK
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
