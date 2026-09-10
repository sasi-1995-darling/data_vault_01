---- SRC LAYER ----
WITH
SRC_C              as ( SELECT * FROM {{ source('qualitypod_sp', 'QLIKVIEW_EXTERNAL_CLAIM_DATA_FILE_SHEET_1') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_C              as ( SELECT * FROM qualitypod_sp.external_claims )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_C as (
    SELECT
    _LINE
      ,CONVERT_TIMEZONE('UTC', IFF(
            PSA_DELETE_IND = 'Y',
            PSA_LOAD_DTS,
            TO_TIMESTAMP(
            REGEXP_REPLACE( _FIVETRAN_SYNCED,
            -- Pattern to capture month, year, day, and the full time part
            '^(\\d{2})-(\\d{4})-(\\d{2}) (\\d{2}:\\d{2}:\\d{2}\\.\\d+).*$',
            -- Rearrange into YYYY-MM-DD HH:MI:SS.FF format
            '\\2-\\1-\\3 \\4'
        ))))                                                           as                                           LOAD_DTS
      , OPEN_CLOSED
      , RISK_CATEGORY
      , CLAIM_TITLE
      , CURRENT_STATUS
      , DESC_OF_ISSUE
      , MATERIAL
      , MATERIAL_DESCRIPTION
      , PARTY_NAME
      , STATUE_OF_LIMITATIONS
      , CLAIM_                                                       as                                       CLAIM_NUMBER
      , MAPPING
      , SALES_ORGANIZATION
      , SALES_DOCUMENT
      , ASSIGNED_TO
      , CLAIMS_TEAM
      , KNOWN_ISSUE
      , CAUSE
      , INSTALL_YEAR
      , OCCURRENCE_DATE
      , CREATION_DATE
      , STATUTE_OF_LIMITATIONS
      , COMPLETION_DATE
      , DAYS_OPEN
      , TPA_FLAG
      , TPA_FILE_NUMBER
      , LITIGATION
      , CLAIM_LEVEL
      , DEMAND
      , BASELINE_RISK
      , CURRENT_RISK
      , APPROVED_
      , CLAIM_COSTS_PRODUCT
      , CLAIM_COSTS_LABOR
      , CLAIM_COSTS_PERSONAL_ISSUE
      , CLAIM_COSTS_DAMAGE_INDEMNITY
      , CLAIM_COSTS_MEDICAL
      , CLAIM_COSTS_LITIGATION
      , CLAIM_COSTS_EXPENSE
      , CLAIM_COSTS_SUMMATION_TOTAL
      , CLAIM_TYPE
      , CLAIM_STATUS
      , ORDER_REASON_CODE
      , CLAIM_REASON
      , SYMPTOM
      , LOCATION
      , CUSTOMER
      , PRODUCT_SERIAL_ID
      , DAYS_TO_CLOSE
      , LANGUAGE
      , DISTRIBUTION_CHANNEL
      , ORDER_REASON
      , PARTY_ROLE
      , PSA_DELETE_IND
      , _FIVETRAN_SYNCED
    FROM SRC_C
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_C as (
    SELECT
        _LINE
      , LOAD_DTS
      , OPEN_CLOSED
      , RISK_CATEGORY
      , CLAIM_TITLE
      , CURRENT_STATUS
      , DESC_OF_ISSUE
      , MATERIAL
      , MATERIAL_DESCRIPTION
      , PARTY_NAME
      , STATUE_OF_LIMITATIONS
      , CLAIM_NUMBER
      , MAPPING
      , SALES_ORGANIZATION
      , SALES_DOCUMENT
      , ASSIGNED_TO
      , CLAIMS_TEAM
      , KNOWN_ISSUE
      , CAUSE
      , INSTALL_YEAR
      , OCCURRENCE_DATE
      , CREATION_DATE
      , STATUTE_OF_LIMITATIONS
      , COMPLETION_DATE
      , DAYS_OPEN
      , TPA_FLAG
      , TPA_FILE_NUMBER
      , LITIGATION
      , CLAIM_LEVEL
      , DEMAND
      , BASELINE_RISK
      , CURRENT_RISK
      , APPROVED_
      , CLAIM_COSTS_PRODUCT
      , CLAIM_COSTS_LABOR
      , CLAIM_COSTS_PERSONAL_ISSUE
      , CLAIM_COSTS_DAMAGE_INDEMNITY
      , CLAIM_COSTS_MEDICAL
      , CLAIM_COSTS_LITIGATION
      , CLAIM_COSTS_EXPENSE
      , CLAIM_COSTS_SUMMATION_TOTAL
      , CLAIM_TYPE
      , CLAIM_STATUS
      , ORDER_REASON_CODE
      , CLAIM_REASON
      , SYMPTOM
      , LOCATION
      , CUSTOMER
      , PRODUCT_SERIAL_ID
      , DAYS_TO_CLOSE
      , LANGUAGE
      , DISTRIBUTION_CHANNEL
      , ORDER_REASON
      , PARTY_ROLE
      , PSA_DELETE_IND
      , _FIVETRAN_SYNCED
    FROM LOGIC_C
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_C as (
    SELECT *
    FROM RENAME_C
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'US.CSV.QLIKVIEW.QLIKVIEW_EXTERNAL_CLAIMS'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_C
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT  
          _LINE
        , LOAD_DTS
        , OPEN_CLOSED 
        , RISK_CATEGORY
        , CLAIM_TITLE
        , CURRENT_STATUS
        , DESC_OF_ISSUE
        , MATERIAL
        , MATERIAL_DESCRIPTION
        , PARTY_NAME
        , STATUE_OF_LIMITATIONS
        , CLAIM_NUMBER
        , MAPPING
        , SALES_ORGANIZATION
        , SALES_DOCUMENT
        , ASSIGNED_TO
        , CLAIMS_TEAM
        , KNOWN_ISSUE
        , CAUSE
        , INSTALL_YEAR
        , OCCURRENCE_DATE
        , CREATION_DATE
        , STATUTE_OF_LIMITATIONS
        , COMPLETION_DATE
        , DAYS_OPEN
        , TPA_FLAG
        , TPA_FILE_NUMBER
        , LITIGATION
        , CLAIM_LEVEL
        , DEMAND
        , BASELINE_RISK
        , CURRENT_RISK
        , APPROVED_
        , CLAIM_COSTS_PRODUCT
        , CLAIM_COSTS_LABOR
        , CLAIM_COSTS_PERSONAL_ISSUE
        , CLAIM_COSTS_DAMAGE_INDEMNITY
        , CLAIM_COSTS_MEDICAL
        , CLAIM_COSTS_LITIGATION
        , CLAIM_COSTS_EXPENSE
        , CLAIM_COSTS_SUMMATION_TOTAL
        , CLAIM_TYPE
        , CLAIM_STATUS
        , ORDER_REASON_CODE
        , CLAIM_REASON
        , SYMPTOM
        , LOCATION
        , CUSTOMER
        , PRODUCT_SERIAL_ID
        , DAYS_TO_CLOSE
        , LANGUAGE
        , DISTRIBUTION_CHANNEL
        , ORDER_REASON
        , PARTY_ROLE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , to_char(coalesce(_LINE,'-1'))                                      as                                            LINE_BK
        , to_char(coalesce(CLAIM_NUMBER,'-1'))                               as                                    CLAIM_NUMBER_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
              COALESCE(NULLIF(TRIM(CAST(CLAIM_NUMBER_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(LINE_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                                  as                                    CLAIM_NUMBER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(_LINE::text), '^^')
            , '||', IFNULL(TRIM(OPEN_CLOSED::text), '^^') 
            , '||', IFNULL(TRIM(RISK_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(CLAIM_TITLE::text), '^^') 
            , '||', IFNULL(TRIM(CURRENT_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(DESC_OF_ISSUE::text), '^^') 
            , '||', IFNULL(TRIM(MATERIAL::text), '^^') 
            , '||', IFNULL(TRIM(MATERIAL_DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(PARTY_NAME::text), '^^') 
            , '||', IFNULL(TRIM(STATUE_OF_LIMITATIONS::text), '^^') 
            , '||', IFNULL(TRIM(CLAIM_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(MAPPING::text), '^^') 
            , '||', IFNULL(TRIM(SALES_ORGANIZATION::text), '^^') 
            , '||', IFNULL(TRIM(SALES_DOCUMENT::text), '^^') 
            , '||', IFNULL(TRIM(ASSIGNED_TO::text), '^^') 
            , '||', IFNULL(TRIM(CLAIMS_TEAM::text), '^^') 
            , '||', IFNULL(TRIM(KNOWN_ISSUE::text), '^^') 
            , '||', IFNULL(TRIM(CAUSE::text), '^^') 
            , '||', IFNULL(TRIM(INSTALL_YEAR::text), '^^') 
            , '||', IFNULL(TRIM(OCCURRENCE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(STATUTE_OF_LIMITATIONS::text), '^^') 
            , '||', IFNULL(TRIM(COMPLETION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(DAYS_OPEN::text), '^^') 
            , '||', IFNULL(TRIM(TPA_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(TPA_FILE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(LITIGATION::text), '^^') 
            , '||', IFNULL(TRIM(CLAIM_LEVEL::text), '^^') 
            , '||', IFNULL(TRIM(DEMAND::text), '^^') 
            , '||', IFNULL(TRIM(BASELINE_RISK::text), '^^') 
            , '||', IFNULL(TRIM(CURRENT_RISK::text), '^^') 
            , '||', IFNULL(TRIM(APPROVED_::text), '^^') 
            , '||', IFNULL(TRIM(CLAIM_COSTS_PRODUCT::text), '^^') 
            , '||', IFNULL(TRIM(CLAIM_COSTS_LABOR::text), '^^') 
            , '||', IFNULL(TRIM(CLAIM_COSTS_PERSONAL_ISSUE::text), '^^') 
            , '||', IFNULL(TRIM(CLAIM_COSTS_DAMAGE_INDEMNITY::text), '^^') 
            , '||', IFNULL(TRIM(CLAIM_COSTS_MEDICAL::text), '^^') 
            , '||', IFNULL(TRIM(CLAIM_COSTS_LITIGATION::text), '^^') 
            , '||', IFNULL(TRIM(CLAIM_COSTS_EXPENSE::text), '^^') 
            , '||', IFNULL(TRIM(CLAIM_COSTS_SUMMATION_TOTAL::text), '^^') 
            , '||', IFNULL(TRIM(CLAIM_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(CLAIM_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_REASON_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CLAIM_REASON::text), '^^') 
            , '||', IFNULL(TRIM(SYMPTOM::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_SERIAL_ID::text), '^^') 
            , '||', IFNULL(TRIM(DAYS_TO_CLOSE::text), '^^') 
            , '||', IFNULL(TRIM(LANGUAGE::text), '^^') 
            , '||', IFNULL(TRIM(DISTRIBUTION_CHANNEL::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_REASON::text), '^^') 
            , '||', IFNULL(TRIM(PARTY_ROLE::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
