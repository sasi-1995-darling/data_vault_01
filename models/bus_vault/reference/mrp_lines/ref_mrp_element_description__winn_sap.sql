---- SRC LAYER ----
WITH
SRC_b              as ( SELECT * FROM {{ ref('v_psa_stg_mrp_element_description__winn_sap') }} as SRC  
                        qualify 1= row_number() over(partition by  PAART order by LOAD_DTS desc))
/*
SRC_b              as ( SELECT * FROM staging.V_PSA_STG_MRP_ELEMENT_DESCRIPTION__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_b as (
    SELECT
        PAART                                                        as                                    ORDER_TYPE_CODE -- MRP ELEMENT CODE
      , SPRAS                                                        as                                       LANGUAGE_KEY
      , PATXT                                                        as                                    ORDER_TYPE_TEXT -- Description for the MRP ELEMENT TYPES
      , LOAD_DTS
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_b as (
    SELECT
        ORDER_TYPE_CODE
      , LANGUAGE_KEY
      , ORDER_TYPE_TEXT
      , LOAD_DTS
    FROM LOGIC_b
)
---- FILTER LAYER ----

, FILTER_b as (
    SELECT *
    FROM RENAME_b
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_b
)

---- FINAL LAYER ----
SELECT
          ORDER_TYPE_CODE
        , LANGUAGE_KEY
        , ORDER_TYPE_TEXT
        , LOAD_DTS
FROM JOIN_RESULT
