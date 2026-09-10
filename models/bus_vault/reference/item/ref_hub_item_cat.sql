---- SRC LAYER ----
WITH
SRC_SLR            as ( SELECT * FROM {{ ref('v_psa_stg_item_cat__lrsn_psft') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ITEM_CAT_BK ORDER BY LOAD_DTS ))=1 )

/*
SRC_SLR            as ( SELECT * FROM STAGING.v_psa_stg_item_cat__LRSN_PSFT Tables )
*/
---- LOGIC LAYER ----

, LOGIC_SLR as (
    SELECT
        ITEM_CAT_BK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SLR
)
---- RENAME LAYER ----

, RENAME_SLR as (
    SELECT
        ITEM_CAT_BK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SLR
)
---- FILTER LAYER ----

, FILTER_SLR as (
    SELECT *
    FROM RENAME_SLR
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_SLR
)

---- FINAL LAYER ----
SELECT
          ITEM_CAT_BK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ITEM_CAT_BK = JOIN_RESULT.ITEM_CAT_BK
)
{% endif %}
{% if not is_incremental() %}
union all

SELECT  GR.VALUE  AS ITEM_CAT_BK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)::TIMESTAMP  as LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}