---- SRC LAYER ----
WITH
SRC_tte21          as ( SELECT * FROM {{ ref('v_psa_stg_ref_po_status__tt_e21') }} as SRC 
                        qualify 1= row_number()over(partition by PO_STATUS_CODE_TYPE order by LOAD_DTS desc) )

/*
SRC_tte21          as ( SELECT * FROM STAGING.v_psa_stg_ref_po_status__tt_e21 )
*/
---- LOGIC LAYER ----

, LOGIC_tte21 as (
    SELECT
        PO_STATUS_CODE_TYPE
      , PO_STATUS_CODE_VALUE
      , PO_STATUS_NUM_VALUE
      , LOAD_DTS
    FROM SRC_tte21
)
---- RENAME LAYER ----

, RENAME_tte21 as (
    SELECT
        PO_STATUS_CODE_TYPE
      , PO_STATUS_CODE_VALUE
      , PO_STATUS_NUM_VALUE
      , LOAD_DTS
    FROM LOGIC_tte21
)
---- FILTER LAYER ----

, FILTER_tte21 as (
    SELECT *
    FROM RENAME_tte21
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_tte21
)

---- FINAL LAYER ----
SELECT
          PO_STATUS_CODE_TYPE
        , PO_STATUS_CODE_VALUE
        , PO_STATUS_NUM_VALUE
        , LOAD_DTS
FROM JOIN_RESULT
