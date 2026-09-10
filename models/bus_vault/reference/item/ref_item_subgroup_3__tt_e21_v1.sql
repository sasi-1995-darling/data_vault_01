---- SRC LAYER ----
WITH
SRC_SPS3TTE        as ( SELECT * FROM {{ ref('v_psa_stg_part_subgrp_3__tt_e21') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PART_SUBGRP3_ID ORDER BY LOAD_DTS DESC))=1 )

/*
SRC_SPS3TTE        as ( SELECT * FROM STAGING.v_psa_stg_part_subgrp_3__tt_e21 )
*/
---- LOGIC LAYER ----

, LOGIC_SPS3TTE as (
    SELECT
        PART_SUBGRP3_ID
      , STATUS
      , PART_SGRP3_DESC
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , _FIVETRAN_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_SPS3TTE
)
---- RENAME LAYER ----

, RENAME_SPS3TTE as (
    SELECT
        PART_SUBGRP3_ID
      , STATUS
      , PART_SGRP3_DESC
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , _FIVETRAN_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_SPS3TTE
)
---- FILTER LAYER ----

, FILTER_SPS3TTE as (
    SELECT *
    FROM RENAME_SPS3TTE
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SPS3TTE
)

---- FINAL LAYER ----
SELECT
          PART_SUBGRP3_ID
        , STATUS
        , PART_SGRP3_DESC
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , _FIVETRAN_ID
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
