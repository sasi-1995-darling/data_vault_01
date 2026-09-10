---- SRC LAYER ----
WITH
SRC_ZZ             as ( SELECT BKCC, INSTALLATION_BK, INSTALLATION_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_installation_event__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY INSTALLATION_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_ZZ             as ( SELECT * FROM STAGING.v_psa_stg_installation_event__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_ZZ as (
    SELECT
        INSTALLATION_HK
      , INSTALLATION_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ZZ
)
---- RENAME LAYER ----

, RENAME_ZZ as (
    SELECT
        INSTALLATION_HK
      , INSTALLATION_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ZZ
)
---- FILTER LAYER ----

, FILTER_ZZ as (
    SELECT *
    FROM RENAME_ZZ
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_ZZ
)

---- FINAL LAYER ----
SELECT
          INSTALLATION_HK
        , INSTALLATION_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.INSTALLATION_HK = JOIN_RESULT.INSTALLATION_HK
)
{% endif %}
{% if not is_incremental() %}

union all

SELECT MD5_BINARY(GR.VALUE)  as INSTALLATION_HK
, GR.VALUE  AS INSTALLATION_BK
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}