---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('menards_psa', 'menards_store_history') }} as SRC 
                        where replace(replace(store_no, chr(0), ''), '"', '')<>'' ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM menards_psa.menards_store_history )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        CONVERT_TIMEZONE('UTC',LOAD_DATE)                            as                                           LOAD_DTS
      , STORE_NO
      , LOCATION_CODE
      , LOCATION_NAME
      , PROTOTYPE
      , REC_DATE
      , OPEN_DATE_1
      , ADDRESS_1
      , ADDRESS_2
      , CITY
      , STATE
      , POSTAL_CD
      , TELEPHONE
      , FAX
      , MARKET
      , CLOSEOUT_START_DATE
      , APPLIANCES
      , SOFT_OPEN
      , LONGITUDE
      , LATITUDE
      , LIVE_GOODS
      , PET_GROCERY
      , OPEN_DATE_2
      , FILE_NAME
      , LOAD_DATE
      , FILE_ROW_NUMBER
      , FILE_LAST_MODIFIED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
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
        LOAD_DTS
      , STORE_NO
      , LOCATION_CODE
      , LOCATION_NAME
      , PROTOTYPE
      , REC_DATE
      , OPEN_DATE_1
      , ADDRESS_1
      , ADDRESS_2
      , CITY
      , STATE
      , POSTAL_CD
      , TELEPHONE
      , FAX
      , MARKET
      , CLOSEOUT_START_DATE
      , APPLIANCES
      , SOFT_OPEN
      , LONGITUDE
      , LATITUDE
      , LIVE_GOODS
      , PET_GROCERY
      , OPEN_DATE_2
      , FILE_NAME
      , LOAD_DATE
      , FILE_ROW_NUMBER
      , FILE_LAST_MODIFIED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
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
    WHERE rec_src = 'US.EXCEL.MENARDS.MENARDS_STORE_HISTORY'
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
          LOAD_DTS
        , STORE_NO::varchar                                            as STORE_BK
        , STORE_NO
        , LOCATION_CODE
        , LOCATION_NAME
        , PROTOTYPE
        , REC_DATE
        , OPEN_DATE_1
        , ADDRESS_1
        , ADDRESS_2
        , CITY
        , STATE
        , POSTAL_CD
        , TELEPHONE
        , FAX
        , MARKET
        , CLOSEOUT_START_DATE
        , APPLIANCES
        , SOFT_OPEN
        , LONGITUDE
        , LATITUDE
        , LIVE_GOODS
        , PET_GROCERY
        , OPEN_DATE_2
        , FILE_NAME
        , LOAD_DATE
        , FILE_ROW_NUMBER
        , FILE_LAST_MODIFIED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(STORE_NO as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as STORE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(LOCATION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION_NAME::text), '^^') 
            , '||', IFNULL(TRIM(PROTOTYPE::text), '^^') 
            , '||', IFNULL(TRIM(REC_DATE::text), '^^') 
            , '||', IFNULL(TRIM(OPEN_DATE_1::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS_1::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS_2::text), '^^') 
            , '||', IFNULL(TRIM(CITY::text), '^^') 
            , '||', IFNULL(TRIM(STATE::text), '^^') 
            , '||', IFNULL(TRIM(POSTAL_CD::text), '^^') 
            , '||', IFNULL(TRIM(TELEPHONE::text), '^^') 
            , '||', IFNULL(TRIM(FAX::text), '^^') 
            , '||', IFNULL(TRIM(MARKET::text), '^^') 
            , '||', IFNULL(TRIM(CLOSEOUT_START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(APPLIANCES::text), '^^') 
            , '||', IFNULL(TRIM(SOFT_OPEN::text), '^^') 
            , '||', IFNULL(TRIM(LONGITUDE::text), '^^') 
            , '||', IFNULL(TRIM(LATITUDE::text), '^^') 
            , '||', IFNULL(TRIM(LIVE_GOODS::text), '^^') 
            , '||', IFNULL(TRIM(PET_GROCERY::text), '^^') 
            , '||', IFNULL(TRIM(OPEN_DATE_2::text), '^^') 
            , '||', IFNULL(TRIM(FILE_NAME::text), '^^') 
            , '||', IFNULL(TRIM(LOAD_DATE::text), '^^') 
            , '||', IFNULL(TRIM(FILE_ROW_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(FILE_LAST_MODIFIED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
