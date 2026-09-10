---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('menards_psa', 'location_lookup') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM menards_psa.location_lookup )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        CONVERT_TIMEZONE('UTC',_FIVETRAN_SYNCED)                     as                                           LOAD_DTS
      , STORE_
      , PROTOTYPE
      , REC_DATE
      , OPEN_DATE
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
      , STORE_
      , 	PROTOTYPE
      , 	REC_DATE
      , 	OPEN_DATE
      , 	ADDRESS_1
      , 	ADDRESS_2
      , 	CITY
      , 	STATE
      , 	POSTAL_CD
      , 	TELEPHONE
      , 	FAX
      , 	MARKET
      , 	CLOSEOUT_START_DATE
      , 	APPLIANCES
      , 	SOFT_OPEN
      , 	LONGITUDE
      , 	LATITUDE
      , 	LIVE_GOODS
      , 	PET_GROCERY
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
    WHERE rec_src = 'US.EXCEL.MENARDS.LOCATION_LOOKUP'
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
        , STORE_::varchar                                              as STORE_BK
        , STORE_
        , 	PROTOTYPE
        , 	REC_DATE
        , 	OPEN_DATE
        , 	ADDRESS_1
        , 	ADDRESS_2
        , 	CITY
        , 	STATE
        , 	POSTAL_CD
        , 	TELEPHONE
        , 	FAX
        , 	MARKET
        , 	CLOSEOUT_START_DATE
        , 	APPLIANCES
        , 	SOFT_OPEN
        , 	LONGITUDE
        , 	LATITUDE
        , 	LIVE_GOODS
        , 	PET_GROCERY
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(STORE_ as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as STORE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(	PROTOTYPE::text), '^^') 
            , '||', IFNULL(TRIM(	REC_DATE::text), '^^') 
            , '||', IFNULL(TRIM(	OPEN_DATE::text), '^^') 
            , '||', IFNULL(TRIM(	ADDRESS_1::text), '^^') 
            , '||', IFNULL(TRIM(	ADDRESS_2::text), '^^') 
            , '||', IFNULL(TRIM(	CITY::text), '^^') 
            , '||', IFNULL(TRIM(	STATE::text), '^^') 
            , '||', IFNULL(TRIM(	POSTAL_CD::text), '^^') 
            , '||', IFNULL(TRIM(	TELEPHONE::text), '^^') 
            , '||', IFNULL(TRIM(	FAX::text), '^^') 
            , '||', IFNULL(TRIM(	MARKET::text), '^^') 
            , '||', IFNULL(TRIM(	CLOSEOUT_START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(	APPLIANCES::text), '^^') 
            , '||', IFNULL(TRIM(	SOFT_OPEN::text), '^^') 
            , '||', IFNULL(TRIM(	LONGITUDE::text), '^^') 
            , '||', IFNULL(TRIM(	LATITUDE::text), '^^') 
            , '||', IFNULL(TRIM(	LIVE_GOODS::text), '^^') 
            , '||', IFNULL(TRIM(	PET_GROCERY::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
