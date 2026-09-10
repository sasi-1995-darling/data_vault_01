---- SRC LAYER ----
WITH
SRC_SLWPG          as ( SELECT * FROM {{ ref('v_psa_stg_pog_weekly__lowes_vpp') }} as SRC 
                        {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %} )

/*
SRC_SLWPG          as ( SELECT * FROM STAGING.v_psa_stg_pog_weekly__lowes_vpp )
*/
---- LOGIC LAYER ----

, LOGIC_SLWPG as (
    SELECT
        STORE_HK
      , HOVBU_ID
      , ITEM_NUMBER
      , LOCATION_ID
      , WEEK_ID
      , HOVBU_DESC
      , ITEM_DESC
      , ASSORTMENT_NUMBER
      , ASSORTMENT_NAME
      , PRODUCT_GROUP_NUMBER
      , PRODUCT_GROUP_NAME
      , MERCHANDISING_SUBDIVISION
      , MERCHANDISING_DIVISION
      , LOCATION_DESC
      , STOCKED_STORES
      , _FIVETRAN_SYNCED
      , _FIVETRAN_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_SLWPG
)
---- RENAME LAYER ----

, RENAME_SLWPG as (
    SELECT
        STORE_HK
      , HOVBU_ID
      , ITEM_NUMBER
      , LOCATION_ID
      , WEEK_ID
      , HOVBU_DESC
      , ITEM_DESC
      , ASSORTMENT_NUMBER
      , ASSORTMENT_NAME
      , PRODUCT_GROUP_NUMBER
      , PRODUCT_GROUP_NAME
      , MERCHANDISING_SUBDIVISION
      , MERCHANDISING_DIVISION
      , LOCATION_DESC
      , STOCKED_STORES
      , _FIVETRAN_SYNCED
      , _FIVETRAN_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_SLWPG
)
---- FILTER LAYER ----

, FILTER_SLWPG as (
    SELECT *
    FROM RENAME_SLWPG
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SLWPG
)

---- FINAL LAYER ----
SELECT
          STORE_HK
        , HOVBU_ID
        , ITEM_NUMBER
        , LOCATION_ID
        , WEEK_ID
        , HOVBU_DESC
        , ITEM_DESC
        , ASSORTMENT_NUMBER
        , ASSORTMENT_NAME
        , PRODUCT_GROUP_NUMBER
        , PRODUCT_GROUP_NAME
        , MERCHANDISING_SUBDIVISION
        , MERCHANDISING_DIVISION
        , LOCATION_DESC
        , STOCKED_STORES
        , _FIVETRAN_SYNCED
        , _FIVETRAN_DELETED
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
	AND existing.HOVBU_ID = JOIN_RESULT.HOVBU_ID
	AND existing.ITEM_NUMBER = JOIN_RESULT.ITEM_NUMBER
	AND existing.WEEK_ID = JOIN_RESULT.WEEK_ID
	AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by STORE_HK, HOVBU_ID, ITEM_NUMBER, WEEK_ID, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS STORE_HK,
GR.VALUE::text AS HOVBU_ID,
GR.VALUE::number AS ITEM_NUMBER,
NULL AS LOCATION_ID,
GR.VALUE::text AS WEEK_ID,
NULL AS HOVBU_DESC,
NULL AS ITEM_DESC,
NULL AS ASSORTMENT_NUMBER,
NULL AS ASSORTMENT_NAME,
NULL AS PRODUCT_GROUP_NUMBER,
NULL AS PRODUCT_GROUP_NAME,
NULL AS MERCHANDISING_SUBDIVISION,
NULL AS MERCHANDISING_DIVISION,
NULL AS LOCATION_DESC,
NULL AS STOCKED_STORES,
NULL AS _FIVETRAN_SYNCED,
NULL AS _FIVETRAN_DELETED,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
