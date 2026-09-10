---- SRC LAYER ----
WITH
SRC_SML            as ( SELECT * FROM {{ ref('v_psa_stg_memolines__ml_ebs') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY MEMO_LINE_BK ORDER BY LOAD_DTS ))=1 )

/*
SRC_SML            as ( SELECT * FROM STAGING.v_psa_stg_MEMOLINES__ML_EBS )
*/
---- LOGIC LAYER ----

, LOGIC_SML as (
    SELECT
        MEMO_LINE_BK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SML
)
---- RENAME LAYER ----

, RENAME_SML as (
    SELECT
        MEMO_LINE_BK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SML
)
---- FILTER LAYER ----

, FILTER_SML as (
    SELECT *
    FROM RENAME_SML
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_SML
)

---- FINAL LAYER ----
SELECT
          MEMO_LINE_BK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.MEMO_LINE_BK = JOIN_RESULT.MEMO_LINE_BK
)
{% endif %}
{% if not is_incremental() %}
union all

SELECT  GR.VALUE  AS MEMO_LINE_BK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)::TIMESTAMP  as LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}