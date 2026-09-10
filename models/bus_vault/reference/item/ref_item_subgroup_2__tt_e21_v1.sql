---- SRC LAYER ----
WITH
SRC_SPS2TTE        as ( SELECT * FROM {{ ref('v_psa_stg_part_subgrp_2__tt_e21') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PART_SUBGRP2_ID ORDER BY LOAD_DTS DESC))=1 )

/*
SRC_SPS2TTE        as ( SELECT * FROM STAGING.v_psa_stg_part_subgrp_2__tt_e21 )
*/
---- LOGIC LAYER ----

, LOGIC_SPS2TTE as (
    SELECT
        PART_SUBGRP2_ID
      , PART_SGRP2_DESC
      , STATUS
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , _FIVETRAN_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_SPS2TTE
)
---- RENAME LAYER ----

, RENAME_SPS2TTE as (
    SELECT
        PART_SUBGRP2_ID
      , PART_SGRP2_DESC
      , STATUS
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , _FIVETRAN_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_SPS2TTE
)
---- FILTER LAYER ----

, FILTER_SPS2TTE as (
    SELECT *
    FROM RENAME_SPS2TTE
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SPS2TTE
)

---- FINAL LAYER ----
SELECT
          PART_SUBGRP2_ID
        , PART_SGRP2_DESC
        , STATUS
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
