---- SRC LAYER ----
WITH
SRC_v1             as ( SELECT ITEM_HK, CHANNEL_ITEM_INVENTORY_LHK, LOAD_DTS, REC_SRC, STORE_HK FROM {{ ref('v_psa_stg_channel_item_inventory__amazon') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CHANNEL_ITEM_INVENTORY_LHK ORDER BY LOAD_DTS ))=1 ),
SRC_v2             as ( SELECT ITEM_HK, CHANNEL_ITEM_INVENTORY_LHK, LOAD_DTS, REC_SRC, STORE_HK FROM {{ ref('v_psa_stg_channel_item_inventory__amazon_moen_inc') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CHANNEL_ITEM_INVENTORY_LHK ORDER BY LOAD_DTS ))=1 ),
SRC_v3             as ( SELECT ITEM_HK, CHANNEL_ITEM_INVENTORY_LHK, LOAD_DTS, REC_SRC, STORE_HK FROM {{ ref('v_psa_stg_channel_item_inventory__amazon_moen_anaheim') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CHANNEL_ITEM_INVENTORY_LHK ORDER BY LOAD_DTS ))=1 )

/*
SRC_v1             as ( SELECT * FROM STAGING.v_psa_stg_channel_item_inventory__amazon )
SRC_v2             as ( SELECT * FROM STAGING.v_psa_stg_channel_item_inventory__amazon_moen_inc )
SRC_v3             as ( SELECT * FROM STAGING.v_psa_stg_channel_item_inventory__amazon_moen_anaheim )

*/
---- LOGIC LAYER ----

, LOGIC_v1 as (
    SELECT
        CHANNEL_ITEM_INVENTORY_LHK
      , ITEM_HK
      , STORE_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_v1
)

, LOGIC_v2 as (
    SELECT
        CHANNEL_ITEM_INVENTORY_LHK
      , ITEM_HK
      , STORE_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_v2
)

, LOGIC_v3 as (
    SELECT
        CHANNEL_ITEM_INVENTORY_LHK
      , ITEM_HK
      , STORE_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_v3
)

---- RENAME LAYER ----

, RENAME_v1 as (
    SELECT
        CHANNEL_ITEM_INVENTORY_LHK
      , ITEM_HK
      , STORE_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_v1
)

, RENAME_v2 as (
    SELECT
        CHANNEL_ITEM_INVENTORY_LHK
      , ITEM_HK
      , STORE_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_v2
)

, RENAME_v3 as (
    SELECT
        CHANNEL_ITEM_INVENTORY_LHK
      , ITEM_HK
      , STORE_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_v3
)

---- FILTER LAYER ----

, FILTER_v1 as (
    SELECT *
    FROM RENAME_v1
)

, FILTER_v2 as (
    SELECT *
    FROM RENAME_v2
)

, FILTER_v3 as (
    SELECT *
    FROM RENAME_v3
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_v1
    UNION ALL
    SELECT *
    FROM FILTER_v2
    UNION ALL
    SELECT *
    FROM FILTER_v3
)

---- FINAL LAYER ----
SELECT
          CHANNEL_ITEM_INVENTORY_LHK
        , ITEM_HK
        , STORE_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
SELECT 1 
FROM {{ this }} existing
WHERE existing.CHANNEL_ITEM_INVENTORY_LHK= JOIN_RESULT.CHANNEL_ITEM_INVENTORY_LHK 
)
{% endif %}
qualify 1 = row_number() over (partition by CHANNEL_ITEM_INVENTORY_LHK order by LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS CHANNEL_ITEM_INVENTORY_LHK,
MD5_BINARY(GR.VALUE) AS ITEM_HK,
MD5_BINARY(GR.VALUE) AS STORE_HK,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
