---- SRC LAYER ----
WITH
SRC_gle            as ( SELECT * FROM {{ ref('v_psa_stg_general_ledger_entries__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY GL_ENTRIES_HK ORDER BY LOAD_DTS ))=1 ),
SRC_glh            as ( SELECT * FROM {{ ref('v_psa_stg_gl_header__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY GENERAL_LEDGER_HK ORDER BY LOAD_DTS ))=1 ),
SRC_le             as ( SELECT * FROM {{ ref('v_psa_stg_legal_entity__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LEGAL_ENTITY_HK ORDER BY LOAD_DTS ))=1 ),
SRC_gla            as ( SELECT * FROM {{ ref('v_psa_stg_gl_account__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY GL_ACCOUNT_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_gle            as ( SELECT * FROM staging.v_psa_stg_general_ledger_entries )
, SRC_glh            as ( SELECT * FROM staging.v_psa_stg_general_ledger_header )
, SRC_le             as ( SELECT * FROM staging.v_psa_stg_legal_entity__winn_sap )
, SRC_gla            as ( SELECT * FROM staging.v_psa_stg_gl_account__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_gle as (
    SELECT
        GL_ENTRIES_HEADER_ACCOUNT_HK
      , GL_ENTRIES_HK
      , GENERAL_LEDGER_HK                                            as                              GLE_GENERAL_LEDGER_HK
      , LEGAL_ENTITY_HK                                              as                                GLE_LEGAL_ENTITY_HK
      , GL_ACCOUNT_HK                                                as                                  GLE_GL_ACCOUNT_HK
      , load_dts
      , rec_src
    FROM SRC_gle
)

, LOGIC_glh as (
    SELECT
        GENERAL_LEDGER_HK
    FROM SRC_glh
)

, LOGIC_le as (
    SELECT
        LEGAL_ENTITY_HK
    FROM SRC_le
)

, LOGIC_gla as (
    SELECT
        GL_ACCOUNT_HK
    FROM SRC_gla
)
---- RENAME LAYER ----

, RENAME_gle as (
    SELECT
        GL_ENTRIES_HEADER_ACCOUNT_HK
      , GL_ENTRIES_HK
      , GLE_GENERAL_LEDGER_HK
      , GLE_LEGAL_ENTITY_HK
      , GLE_GL_ACCOUNT_HK
      , load_dts
      , rec_src
    FROM LOGIC_gle
)

, RENAME_glh as (
    SELECT
        GENERAL_LEDGER_HK
    FROM LOGIC_glh
)

, RENAME_le as (
    SELECT
        LEGAL_ENTITY_HK
    FROM LOGIC_le
)

, RENAME_gla as (
    SELECT
        GL_ACCOUNT_HK
    FROM LOGIC_gla
)
---- FILTER LAYER ----

, FILTER_gle as (
    SELECT *
    FROM RENAME_gle
)

, FILTER_glh as (
    SELECT *
    FROM RENAME_glh
)

, FILTER_le as (
    SELECT *
    FROM RENAME_le
)

, FILTER_gla as (
    SELECT *
    FROM RENAME_gla
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_gle
    INNER JOIN FILTER_glh
        ON FILTER_gle.GLE_GENERAL_LEDGER_HK = FILTER_glh.GENERAL_LEDGER_HK
    INNER JOIN FILTER_le
        ON FILTER_gle.GLE_LEGAL_ENTITY_HK = FILTER_le.LEGAL_ENTITY_HK
    INNER JOIN FILTER_gla
        ON FILTER_gle.GLE_GL_ACCOUNT_HK = FILTER_gla.GL_ACCOUNT_HK
)

---- FINAL LAYER ----
SELECT
          GL_ENTRIES_HEADER_ACCOUNT_HK
        , GENERAL_LEDGER_HK
        , GL_ENTRIES_HK
        , LEGAL_ENTITY_HK
        , GL_ACCOUNT_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.GENERAL_LEDGER_HK = JOIN_RESULT.GENERAL_LEDGER_HK 
)
{% endif %}

{% if not is_incremental() %}
union all
SELECT 

MD5_BINARY(GR.VALUE) AS GL_ENTRIES_HEADER_CHART_HK
, MD5_BINARY(GR.VALUE) AS GENERAL_LEDGER_HK 
, MD5_BINARY(GR.VALUE) AS GL_ENTRIES_HK
, MD5_BINARY(GR.VALUE) AS LEGAL_ENTITY_HK
, MD5_BINARY(GR.VALUE) AS GL_ACCOUNT_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}