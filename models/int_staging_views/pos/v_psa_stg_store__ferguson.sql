---- SRC LAYER ----
WITH
SRC_S              as ( SELECT _FILE, _MODIFIED, _FIVETRAN_SYNCED, LEGACY_LOCATION_ID, BRANCH, ZIP, STATE, LOCATION_CLOSE_DATE, COMPANY, DISTRICT, BRANCH_NAME, CITY, LEGACY_MAIN_BRANCH, ADDRESS_1, ADDRESS_2, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSA_DELETE_IND, _LINE FROM {{ source('ferguson', 'ff_ferguson_branch_index') }} as SRC 
                        
                        /* The following qualify clause is required to pull the most recent row pushed to PSA based on these PK columns*/
                        qualify 1 = row_number()over (partition by branch order by psa_load_dts desc) ),
SRC_A              as ( SELECT REC_SRC, BKCC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM ferguson.ff_ferguson_branch_index )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        coalesce(nullif(trim(BRANCH),''),'-1')                       as                                           STORE_BK
      , _FILE
      , _MODIFIED
      , _FIVETRAN_SYNCED
      , LEGACY_LOCATION_ID
      , BRANCH
      , ZIP
      , lpad(substring(case when position( '-',trim(zip),1) > 0 then left(trim(zip),position( '-',trim(zip),1)-1) else trim(zip) end,1,5),5,'0') as                                    BRANCH_ZIP_CODE
      , STATE
      , LOCATION_CLOSE_DATE
      , COMPANY
      , DISTRICT
      , BRANCH_NAME
      , CITY
      , LEGACY_MAIN_BRANCH
      , ADDRESS_1
      , ADDRESS_2
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
      , _LINE
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
        STORE_BK
      , _FILE
      , _MODIFIED
      , _FIVETRAN_SYNCED
      , LEGACY_LOCATION_ID
      , BRANCH
      , ZIP
      , BRANCH_ZIP_CODE
      , STATE
      , LOCATION_CLOSE_DATE
      , COMPANY
      , DISTRICT
      , BRANCH_NAME
      , CITY
      , LEGACY_MAIN_BRANCH
      , ADDRESS_1
      , ADDRESS_2
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , _LINE
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
    WHERE rec_src = 'US.EXCEL.FERGUSON.FF_FERGUSON_BRANCH_INDEX'
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
          STORE_BK
        , _LINE::varchar                                               as _LINE
        , _FILE
        , _MODIFIED
        , _FIVETRAN_SYNCED
        , LEGACY_LOCATION_ID
        , BRANCH
        , ZIP
        , BRANCH_ZIP_CODE
        , STATE
        , LOCATION_CLOSE_DATE
        , COMPANY
        , DISTRICT
        , BRANCH_NAME
        , CITY
        , LEGACY_MAIN_BRANCH
        , ADDRESS_1
        , ADDRESS_2
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(STORE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as STORE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(_MODIFIED::text), '^^') 
            , '||', IFNULL(TRIM(LEGACY_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(BRANCH::text), '^^') 
            , '||', IFNULL(TRIM(ZIP::text), '^^') 
            , '||', IFNULL(TRIM(STATE::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION_CLOSE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(COMPANY::text), '^^') 
            , '||', IFNULL(TRIM(DISTRICT::text), '^^') 
            , '||', IFNULL(TRIM(BRANCH_NAME::text), '^^') 
            , '||', IFNULL(TRIM(CITY::text), '^^') 
            , '||', IFNULL(TRIM(LEGACY_MAIN_BRANCH::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS_1::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS_2::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
