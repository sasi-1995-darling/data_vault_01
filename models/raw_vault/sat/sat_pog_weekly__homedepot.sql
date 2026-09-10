---- SRC LAYER ----
WITH
SRC_spgwkhd        as ( SELECT * FROM {{ ref('v_psa_stg_pog_weekly__homedepot') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   )

/*
SRC_spgwkhd        as ( SELECT * FROM STAGING.v_psa_stg_pog_weekly__homedepot )
*/
---- LOGIC LAYER ----

, LOGIC_spgwkhd as (
    SELECT
        STORE_HK
      , D_STORE_NBR
      , MANUF_PART_NUMBER
      , SKU_NBR
      , WEEK
      , HOME_DEPOT_ACCOUNT
      , D_ASSORTMENT
      , D_ACTIVE_SKU_2
      , D_POG_2
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_spgwkhd
)
---- RENAME LAYER ----

, RENAME_spgwkhd as (
    SELECT
        STORE_HK
      , D_STORE_NBR
      , MANUF_PART_NUMBER
      , SKU_NBR
      , WEEK
      , HOME_DEPOT_ACCOUNT
      , D_ASSORTMENT
      , D_ACTIVE_SKU_2
      , D_POG_2
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_spgwkhd
)
---- FILTER LAYER ----

, FILTER_spgwkhd as (
    SELECT *
    FROM RENAME_spgwkhd
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_spgwkhd
)

---- FINAL LAYER ----
SELECT
          STORE_HK
        , D_STORE_NBR
        , MANUF_PART_NUMBER
        , SKU_NBR
        , WEEK
        , HOME_DEPOT_ACCOUNT
        , D_ASSORTMENT
        , D_ACTIVE_SKU_2
        , D_POG_2
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.STORE_HK = JOIN_RESULT.STORE_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by STORE_HK, SKU_NBR, HOME_DEPOT_ACCOUNT, D_POG_2, D_ACTIVE_SKU_2, D_ASSORTMENT, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS STORE_HK,
GR.VALUE::text AS D_STORE_NBR,
NULL AS MANUF_PART_NUMBER,
GR.VALUE::text AS SKU_NBR,
GR.VALUE::text AS WEEK,
GR.VALUE::text AS HOME_DEPOT_ACCOUNT,
GR.VALUE::text AS D_ASSORTMENT,
GR.VALUE::text AS D_ACTIVE_SKU_2,
GR.VALUE::text AS D_POG_2,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
