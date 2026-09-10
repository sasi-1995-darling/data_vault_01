---- SRC LAYER ----
WITH
SRC_SSALLR         as ( SELECT * FROM {{ ref('v_psa_stg_salesman_info__lrsn_psft') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SALES_REP_HK ORDER BY LOAD_DTS ))=1 ),
SRC_SBIHLR         as ( SELECT * FROM {{ ref('v_psa_stg_bi_hdr__lrsn_psft') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SALES_REP_HK ORDER BY LOAD_DTS ))=1 ),
SRC_SSALTT         as ( SELECT * FROM {{ ref('v_psa_stg_arsalesman__tt_e21') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SALES_REP_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_SSALLR         as ( SELECT * FROM STAGING.v_psa_stg_salesman_info__lrsn_psft )
, SRC_SBIHLR         as ( SELECT * FROM STAGING.v_psa_stg_bi_hdr__lrsn_psft )
, SRC_SSALTT         as ( SELECT * FROM STAGING.v_psa_stg_arsalesman_tt_e21 )
*/
---- LOGIC LAYER ----

, LOGIC_SSALLR as (
    SELECT
        SALES_REP_HK
      , SALES_REP_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SSALLR
)

, LOGIC_SBIHLR as (
    SELECT
        SALES_REP_HK
      , SALES_REP_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SBIHLR
)

, LOGIC_SSALTT as (
    SELECT
        SALES_REP_HK
      , SALES_REP_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SSALTT
)
---- RENAME LAYER ----

, RENAME_SSALLR as (
    SELECT
        SALES_REP_HK
      , SALES_REP_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SSALLR
)

, RENAME_SBIHLR as (
    SELECT
        SALES_REP_HK
      , SALES_REP_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SBIHLR
)

, RENAME_SSALTT as (
    SELECT
        SALES_REP_HK
      , SALES_REP_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SSALTT
)
---- FILTER LAYER ----

, FILTER_SSALLR as (
    SELECT *
    FROM RENAME_SSALLR
)

, FILTER_SBIHLR as (
    SELECT *
    FROM RENAME_SBIHLR
    WHERE SALES_REP_HK NOT IN (
        SELECT SALES_REP_HK
        FROM FILTER_SSALLR)
)

, FILTER_SSALTT as (
    SELECT *
    FROM RENAME_SSALTT
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_SSALLR
    UNION ALL
    SELECT * FROM FILTER_SBIHLR
    UNION ALL
    SELECT * FROM FILTER_SSALTT
)

---- FINAL LAYER ----
SELECT
          SALES_REP_HK
        , SALES_REP_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.SALES_REP_HK = JOIN_RESULT.SALES_REP_HK
)
{% endif %}
{% if not is_incremental() %}
union all

SELECT MD5_BINARY(GR.VALUE)  SALES_REP_HK
, GR.VALUE  AS SALES_REP_BK
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)::TIMESTAMP  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}