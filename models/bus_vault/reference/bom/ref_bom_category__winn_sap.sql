---- SRC LAYER ----
WITH
SRC_b              as ( SELECT * FROM {{ ref('v_psa_stg_bom_category__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by DOMNAME,DDLANGUAGE,AS4LOCAL,VALPOS,AS4VERS order by LOAD_DTS desc))

/*
SRC_b              as ( SELECT * FROM staging.V_PSA_STG_BOM_CATEGORY__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_b as (
    SELECT
        DOMVALUE_L                                                   as                                      CATEGORY_CODE
      , DDLANGUAGE                                                   as                                       LANGUAGE_KEY
      , DDTEXT                                                       as                                      CATEGORY_TEXT
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_b as (
    SELECT
        CATEGORY_CODE
      , LANGUAGE_KEY
      , CATEGORY_TEXT
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
          CATEGORY_CODE
        , LANGUAGE_KEY
        , CATEGORY_TEXT
FROM JOIN_RESULT
