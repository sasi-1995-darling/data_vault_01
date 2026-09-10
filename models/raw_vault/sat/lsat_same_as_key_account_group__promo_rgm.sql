---- SRC LAYER ----
WITH
SRC_PROMOXREF      as ( SELECT * FROM {{ ref('v_psa_stg_retailer_key_account_group_xref__promo_rgm') }} as SRC 
                        {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %} )

/*
SRC_PROMOXREF      as ( SELECT * FROM STAGING.v_psa_stg_retailer_key_account_group_xref__promo_rgm )
*/
---- LOGIC LAYER ----

, LOGIC_PROMOXREF as (
    SELECT
        SLNK_KEY_ACCOUNT_GROUP_HK
      , _FILE
      , _LINE
      , _MODIFIED
      , _FIVETRAN_SYNCED
      , RETAILER_REC_SRC
      , RETAILER_KEY_ACCOUNT_GROUP
      , RETAILER
      , ERP_KEY_ACCOUNT_GROUP
      , ERP_REC_SRC
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_PROMOXREF
)
---- RENAME LAYER ----

, RENAME_PROMOXREF as (
    SELECT
        SLNK_KEY_ACCOUNT_GROUP_HK
      , _FILE
      , _LINE
      , _MODIFIED
      , _FIVETRAN_SYNCED
      , RETAILER_REC_SRC
      , RETAILER_KEY_ACCOUNT_GROUP
      , RETAILER
      , ERP_KEY_ACCOUNT_GROUP
      , ERP_REC_SRC
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_PROMOXREF
)
---- FILTER LAYER ----

, FILTER_PROMOXREF as (
    SELECT *
    FROM RENAME_PROMOXREF
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_PROMOXREF
)

---- FINAL LAYER ----
SELECT
          SLNK_KEY_ACCOUNT_GROUP_HK
        , _FILE
        , _LINE
        , _MODIFIED
        , _FIVETRAN_SYNCED
        , RETAILER_REC_SRC
        , RETAILER_KEY_ACCOUNT_GROUP
        , RETAILER
        , ERP_KEY_ACCOUNT_GROUP
        , ERP_REC_SRC
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
    WHERE existing.SLNK_KEY_ACCOUNT_GROUP_HK = JOIN_RESULT.SLNK_KEY_ACCOUNT_GROUP_HK
       AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by SLNK_KEY_ACCOUNT_GROUP_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS SLNK_KEY_ACCOUNT_GROUP_HK,
NULL AS _FILE,
NULL AS _LINE,
NULL AS _MODIFIED,
NULL AS _FIVETRAN_SYNCED,
NULL AS RETAILER_REC_SRC,
GR.VALUE::text AS RETAILER_KEY_ACCOUNT_GROUP,
NULL AS RETAILER,
GR.VALUE::text AS ERP_KEY_ACCOUNT_GROUP,
GR.VALUE::text AS ERP_REC_SRC,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
