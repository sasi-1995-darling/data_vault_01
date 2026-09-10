---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('tt_gpd', 'dbo_iv40700') }} as SRC 
                        /*The following qualify clause is required to pick the first entered record to resolve an issue with the great plains tables in PSA where duplicate records are being loaded for every table every day */
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY LOCNCODE ORDER BY PSA_LOAD_DTS) ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM tt_gpd.dbo_iv40700 )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        coalesce(nullif(trim(LOCNCODE), ''), '-1')                   as                                           PLANT_BK
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
      , CONVERT_TIMEZONE('UTC',PSA_LOAD_DTS)                         as                                           LOAD_DTS
    FROM SRC_S
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        PLANT_BK
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
    FROM LOGIC_S
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USOHMA.MSSQL.GPPRD.DBO_IV40700'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          PLANT_BK
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
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(LOCNDSCR::text), '^^') 
            , '||', IFNULL(TRIM(NOTEINDX::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS1::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS2::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS3::text), '^^') 
            , '||', IFNULL(TRIM(CITY::text), '^^') 
            , '||', IFNULL(TRIM(STATE::text), '^^') 
            , '||', IFNULL(TRIM(ZIPCODE::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(PHONE1::text), '^^') 
            , '||', IFNULL(TRIM(PHONE2::text), '^^') 
            , '||', IFNULL(TRIM(PHONE3::text), '^^') 
            , '||', IFNULL(TRIM(FAXNUMBR::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION_SEGMENT::text), '^^') 
            , '||', IFNULL(TRIM(STAXSCHD::text), '^^') 
            , '||', IFNULL(TRIM(PCTAXSCH::text), '^^') 
            , '||', IFNULL(TRIM(INCLDDINPLNNNG::text), '^^') 
            , '||', IFNULL(TRIM(PORECEIPTBIN::text), '^^') 
            , '||', IFNULL(TRIM(PORETRNBIN::text), '^^') 
            , '||', IFNULL(TRIM(SOFULFILLMENTBIN::text), '^^') 
            , '||', IFNULL(TRIM(SORETURNBIN::text), '^^') 
            , '||', IFNULL(TRIM(BOMRCPTBIN::text), '^^') 
            , '||', IFNULL(TRIM(MATERIALISSUEBIN::text), '^^') 
            , '||', IFNULL(TRIM(MORECEIPTBIN::text), '^^') 
            , '||', IFNULL(TRIM(REPAIRISSUESBIN::text), '^^') 
            , '||', IFNULL(TRIM(WMSINT::text), '^^') 
            , '||', IFNULL(TRIM(PICKTICKETSITEOPT::text), '^^') 
            , '||', IFNULL(TRIM(BINBREAK::text), '^^') 
            , '||', IFNULL(TRIM(CCODE::text), '^^') 
            , '||', IFNULL(TRIM(DECLID::text), '^^') 
            , '||', IFNULL(TRIM(DEX_ROW_ID::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
