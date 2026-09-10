---- SRC LAYER ----
WITH
SRC_SPLTTGP        as ( SELECT * FROM {{ ref('v_psa_stg_plant__tt_gp') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SPLTTGP        as ( SELECT * FROM STAGING.v_psa_stg_plant__tt_gp )
*/
---- LOGIC LAYER ----

, LOGIC_SPLTTGP as (
    SELECT
        PLANT_HK
      , LOCNCODE
      , LOCNDSCR
      , NOTEINDX
      , ADDRESS1
      , ADDRESS2
      , ADDRESS3
      , CITY
      , STATE
      , ZIPCODE
      , COUNTRY
      , PHONE1
      , PHONE2
      , PHONE3
      , FAXNUMBR
      , LOCATION_SEGMENT
      , STAXSCHD
      , PCTAXSCH
      , INCLDDINPLNNNG
      , PORECEIPTBIN
      , PORETRNBIN
      , SOFULFILLMENTBIN
      , SORETURNBIN
      , BOMRCPTBIN
      , MATERIALISSUEBIN
      , MORECEIPTBIN
      , REPAIRISSUESBIN
      , WMSINT
      , PICKTICKETSITEOPT
      , BINBREAK
      , CCODE
      , DECLID
      , DEX_ROW_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_SPLTTGP
)
---- RENAME LAYER ----

, RENAME_SPLTTGP as (
    SELECT
        PLANT_HK
      , LOCNCODE
      , LOCNDSCR
      , NOTEINDX
      , ADDRESS1
      , ADDRESS2
      , ADDRESS3
      , CITY
      , STATE
      , ZIPCODE
      , COUNTRY
      , PHONE1
      , PHONE2
      , PHONE3
      , FAXNUMBR
      , LOCATION_SEGMENT
      , STAXSCHD
      , PCTAXSCH
      , INCLDDINPLNNNG
      , PORECEIPTBIN
      , PORETRNBIN
      , SOFULFILLMENTBIN
      , SORETURNBIN
      , BOMRCPTBIN
      , MATERIALISSUEBIN
      , MORECEIPTBIN
      , REPAIRISSUESBIN
      , WMSINT
      , PICKTICKETSITEOPT
      , BINBREAK
      , CCODE
      , DECLID
      , DEX_ROW_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_SPLTTGP
)
---- FILTER LAYER ----

, FILTER_SPLTTGP as (
    SELECT *
    FROM RENAME_SPLTTGP
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SPLTTGP
)

---- FINAL LAYER ----
SELECT
          PLANT_HK
        , LOCNCODE
        , LOCNDSCR
        , NOTEINDX
        , ADDRESS1
        , ADDRESS2
        , ADDRESS3
        , CITY
        , STATE
        , ZIPCODE
        , COUNTRY
        , PHONE1
        , PHONE2
        , PHONE3
        , FAXNUMBR
        , LOCATION_SEGMENT
        , STAXSCHD
        , PCTAXSCH
        , INCLDDINPLNNNG
        , PORECEIPTBIN
        , PORETRNBIN
        , SOFULFILLMENTBIN
        , SORETURNBIN
        , BOMRCPTBIN
        , MATERIALISSUEBIN
        , MORECEIPTBIN
        , REPAIRISSUESBIN
        , WMSINT
        , PICKTICKETSITEOPT
        , BINBREAK
        , CCODE
        , DECLID
        , DEX_ROW_ID
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
    WHERE existing.PLANT_HK= JOIN_RESULT.PLANT_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by PLANT_HK, DEX_ROW_ID, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS PLANT_HK,
GR.VALUE::text AS LOCNCODE,
NULL AS LOCNDSCR,
NULL AS NOTEINDX,
NULL AS ADDRESS1,
NULL AS ADDRESS2,
NULL AS ADDRESS3,
NULL AS CITY,
NULL AS STATE,
NULL AS ZIPCODE,
NULL AS COUNTRY,
NULL AS PHONE1,
NULL AS PHONE2,
NULL AS PHONE3,
NULL AS FAXNUMBR,
NULL AS LOCATION_SEGMENT,
NULL AS STAXSCHD,
NULL AS PCTAXSCH,
NULL AS INCLDDINPLNNNG,
NULL AS PORECEIPTBIN,
NULL AS PORETRNBIN,
NULL AS SOFULFILLMENTBIN,
NULL AS SORETURNBIN,
NULL AS BOMRCPTBIN,
NULL AS MATERIALISSUEBIN,
NULL AS MORECEIPTBIN,
NULL AS REPAIRISSUESBIN,
NULL AS WMSINT,
NULL AS PICKTICKETSITEOPT,
NULL AS BINBREAK,
NULL AS CCODE,
NULL AS DECLID,
NULL AS DEX_ROW_ID,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
