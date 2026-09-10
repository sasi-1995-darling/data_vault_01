---- SRC LAYER ----
WITH
SRC_SPSTTE         as ( SELECT * FROM {{ ref('v_psa_stg_part_subgrp__tt_e21') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PART_SUBGRP_ID ORDER BY LOAD_DTS DESC))=1 )

/*
SRC_SPSTTE         as ( SELECT * FROM STAGING.v_psa_stg_part_subgrp__tt_e21 )
*/
---- LOGIC LAYER ----

, LOGIC_SPSTTE as (
    SELECT
        PART_SUBGRP_ID
      , STATUS
      , PART_SGRP_DESC
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , _FIVETRAN_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_SPSTTE
)
---- RENAME LAYER ----

, RENAME_SPSTTE as (
    SELECT
        PART_SUBGRP_ID
      , STATUS
      , PART_SGRP_DESC
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , _FIVETRAN_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_SPSTTE
)
---- FILTER LAYER ----

, FILTER_SPSTTE as (
    SELECT *
    FROM RENAME_SPSTTE
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SPSTTE
)

---- FINAL LAYER ----
SELECT
          PART_SUBGRP_ID
        , STATUS
        , PART_SGRP_DESC
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
