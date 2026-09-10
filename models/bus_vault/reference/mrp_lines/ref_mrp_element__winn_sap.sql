---- SRC LAYER ----
WITH
SRC_b              as ( SELECT * FROM {{ ref('v_psa_stg_mrp_element__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by  DOMVALUE_L order by LOAD_DTS desc))

/*
SRC_b              as ( SELECT * FROM staging.V_PSA_STG_MRP_ELEMENT__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_b as (
    SELECT
        DDLANGUAGE                                                   as                                   LANGUAGE_KEY
      , DDTEXT                                                       as                                   MRP_ELEMENT_TEXT   -- Holds Descriptive Text For Mrp Element
      , DOMVALUE_L                                                   as                                   MRP_ELEMENT_CODE   -- Mrp Element Code 
      , LOAD_DTS
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_b as (
    SELECT
         LANGUAGE_KEY
      ,  MRP_ELEMENT_TEXT
      ,  MRP_ELEMENT_CODE
      ,  LOAD_DTS
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
         LANGUAGE_KEY
      ,  MRP_ELEMENT_TEXT
      ,  MRP_ELEMENT_CODE
      ,  LOAD_DTS
FROM JOIN_RESULT
