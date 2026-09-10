---- SRC LAYER ----
WITH
SRC_SPTTE          as ( SELECT * FROM {{ ref('v_psa_stg_part_grp__tt_e21') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PART_GRP_ID ORDER BY LOAD_DTS DESC))=1 )

/*
SRC_SPTTE          as ( SELECT * FROM STAGING.v_psa_stg_part_grp__tt_e21 )
*/
---- LOGIC LAYER ----

, LOGIC_SPTTE as (
    SELECT
        PART_GRP_ID
      , PART_TYPE
      , STATUS
      , ADD_DATE
      , UPDATE_DATE
      , UPDATE_USER
      , ADD_USER
      , OBS_DATE
      , PART_GRP_DESC
      , MANAGER_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , _FIVETRAN_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_SPTTE
)
---- RENAME LAYER ----

, RENAME_SPTTE as (
    SELECT
        PART_GRP_ID
      , PART_TYPE
      , STATUS
      , ADD_DATE
      , UPDATE_DATE
      , UPDATE_USER
      , ADD_USER
      , OBS_DATE
      , PART_GRP_DESC
      , MANAGER_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , _FIVETRAN_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_SPTTE
)
---- FILTER LAYER ----

, FILTER_SPTTE as (
    SELECT *
    FROM RENAME_SPTTE
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SPTTE
)

---- FINAL LAYER ----
SELECT
          PART_GRP_ID
        , PART_TYPE
        , STATUS
        , ADD_DATE
        , UPDATE_DATE
        , UPDATE_USER
        , ADD_USER
        , OBS_DATE
        , PART_GRP_DESC
        , MANAGER_ID
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
