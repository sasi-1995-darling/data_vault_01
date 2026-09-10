---- SRC LAYER ----
WITH
SRC_cc          as ( SELECT * FROM {{ ref('v_psa_stg_gl_company_code__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY GL_ACCOUNT_DETAILS_HK ORDER BY LOAD_DTS ))=1 )


/*
SRC_cc             as ( SELECT * FROM None.v_psa_stg_gl_company_code__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_cc as (
    SELECT
        GL_ACCOUNT_DETAILS_HK
      , GL_ACCOUNT_HK
      , LEGAL_ENTITY_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_cc
)
---- RENAME LAYER ----

, RENAME_cc as (
    SELECT
        GL_ACCOUNT_DETAILS_HK
      , GL_ACCOUNT_HK
      , LEGAL_ENTITY_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_cc
)
---- FILTER LAYER ----

, FILTER_cc as (
    SELECT *
    FROM RENAME_cc
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_cc
)

---- FINAL LAYER ----
SELECT
          GL_ACCOUNT_DETAILS_HK
        , GL_ACCOUNT_HK
        , LEGAL_ENTITY_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.GL_ACCOUNT_DETAILS_HK = JOIN_RESULT.GL_ACCOUNT_DETAILS_HK
)
{% endif %}

{% if not is_incremental() %}
union all
SELECT 

MD5_BINARY(GR.VALUE) AS GL_ACCOUNT_DETAILS_HK
, MD5_BINARY(GR.VALUE) AS GL_ACCOUNT_HK
, MD5_BINARY(GR.VALUE) AS LEGAL_ENTITY_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}