---- SRC LAYER ----
WITH
SRC_S1             as   ( {% if not is_incremental() %}
                            SELECT * FROM {{ ref('v_psa_stg_prod_retailer_rating__appbot') }} as SRC 
                        {% else %}
                            SELECT * FROM {{ this }} where false
                        {% endif %}                           
                        ),
SRC_S2             as ( SELECT * FROM {{ ref('v_psa_stg_prod_retailer_rating__appbot_fivetran') }} as SRC 
                         {% if is_incremental() %}
                            where
                                src.load_dts >= (
                                    select
                                        coalesce(
                                            dateadd('hour', -1, max(load_dts)), '1900-01-01'::timestamp
                                        )
                                    from {{ this }}
                                    where rec_src = 'US.APPBOT_FT.RATINGS'
                                )
                         {% endif %}  )

/*
SRC_S1             as ( SELECT * FROM staging.v_psa_stg_prod_retailer_rating__appbot )
SRC_S2             as ( SELECT * FROM staging.v_psa_stg_prod_retailer_rating__appbot_fivetran )
*/
---- LOGIC LAYER ----

, LOGIC_S1 as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , APP_ID
      , CREATED_AT
      , COUNTRY
      , COUNTRY_ID
      , COUNTRY_CODE
      , STAR_1
      , STAR_2
      , STAR_3
      , STAR_4
      , STAR_5
      , TOTAL
      , AVG
      , VERSION
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_S1
)

, LOGIC_S2 as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , APP_ID
      , CREATED_AT
      , COUNTRY
      , COUNTRY_ID
      , COUNTRY_CODE
      , STAR_1
      , STAR_2
      , STAR_3
      , STAR_4
      , STAR_5
      , TOTAL
      , AVG
      , VERSION
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_S2
)
---- RENAME LAYER ----

, RENAME_S1 as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , APP_ID
      , CREATED_AT
      , COUNTRY
      , COUNTRY_ID
      , COUNTRY_CODE
      , STAR_1
      , STAR_2
      , STAR_3
      , STAR_4
      , STAR_5
      , TOTAL
      , AVG
      , VERSION
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_S1
)

, RENAME_S2 as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , APP_ID
      , CREATED_AT
      , COUNTRY
      , COUNTRY_ID
      , COUNTRY_CODE
      , STAR_1
      , STAR_2
      , STAR_3
      , STAR_4
      , STAR_5
      , TOTAL
      , AVG
      , VERSION
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_S2
)
---- FILTER LAYER ----

, FILTER_S1 as (
    SELECT *
    FROM RENAME_S1
)

, FILTER_S2 as (
    SELECT *
    FROM RENAME_S2
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_S1
    UNION ALL
    SELECT * FROM FILTER_S2
)

---- FINAL LAYER ----
SELECT
          PRODUCT_RETAILER_HK
        , LOAD_DTS
        , APP_ID
        , CREATED_AT
        , COUNTRY
        , COUNTRY_ID
        , COUNTRY_CODE
        , STAR_1
        , STAR_2
        , STAR_3
        , STAR_4
        , STAR_5
        , TOTAL
        , AVG
        , VERSION
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PRODUCT_RETAILER_HK = JOIN_RESULT.PRODUCT_RETAILER_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
qualify 1= row_number()over(partition by PRODUCT_RETAILER_HK, HASHDIFF order by CREATED_AT, PSA_LOAD_DTS)
{% if not is_incremental() %}
union all
SELECT
MD5_BINARY(GR.VALUE) AS PRODUCT_RETAILER_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, null  as APP_ID
, ('1900-01-01')  as CREATED_AT
, GR.VALUE  as COUNTRY
, null  as COUNTRY_ID
, null  as COUNTRY_CODE
, null  as STAR_1
, null  as STAR_2
, null  as STAR_3
, null  as STAR_4
, null  as STAR_5
, null  as TOTAL
, null  as AVG
, null  as VERSION
, '1900-01-01'::TIMESTAMP_LTZ  as PSA_LOAD_DTS
, null  as PSA_RECORD_SOURCE
, null  as PSA_DELETE_IND

, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, ''::BINARY as HASH_DIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

{% endif %}