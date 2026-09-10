---- SRC LAYER ----
WITH
SRC AS (
    SELECT
        _PARTNER_NUMBER,
        BUSINESS_NAME,
        PSA_DELETE_IND,
        PSA_LOAD_DTS
    FROM {{ source('custom_fivetran_smartsheet_flo_insurance_partner', 'insurance_partner_name') }}
)

---- LOGIC LAYER ----
, LOGIC AS (
    SELECT
        _PARTNER_NUMBER                                      AS PARTNER_NUMBER,
        BUSINESS_NAME                                        AS INSURANCE_PARTNER,
        PSA_DELETE_IND,
        CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)               AS LOAD_DTS
    FROM SRC
)

---- FINAL LAYER ----
SELECT
      PARTNER_NUMBER
    , INSURANCE_PARTNER
    , PSA_DELETE_IND
    , LOAD_DTS
FROM LOGIC
