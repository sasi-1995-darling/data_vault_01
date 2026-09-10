---- SRC LAYER ----
WITH
SRC_c              as ( SELECT * FROM {{ ref('v_psa_stg_external_claims') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CLAIM_NUMBER_HK ORDER BY LOAD_DTS desc))=1 )

/*
SRC_c              as ( SELECT * FROM STAGING.v_psa_stg_external_claims )
*/
---- LOGIC LAYER ----

, LOGIC_c as (
    SELECT
        CLAIM_NUMBER_HK
      , CLAIM_NUMBER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_c
)
---- RENAME LAYER ----

, RENAME_c as (
    SELECT
        CLAIM_NUMBER_HK 
      , CLAIM_NUMBER_BK 
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_c
)
---- FILTER LAYER ----

, FILTER_c as (
    SELECT *
    FROM RENAME_c
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_c
)

---- FINAL LAYER ----
SELECT
          CLAIM_NUMBER_HK 
        , CLAIM_NUMBER_BK 
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if not is_incremental() %}
 union all
 
 SELECT MD5_BINARY(GR.VALUE) CLAIM_NUMBER_HK
 , GR.VALUE AS CLAIM_NUMBER_BK
 , DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC
 , CONVERT_TIMEZONE('UTC','1900-01-01') AS LOAD_DTS
 , 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
 FROM
 TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
 {% endif %}