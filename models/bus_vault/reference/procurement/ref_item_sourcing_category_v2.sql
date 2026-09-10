{{
    config(
        materialized='table',
        copy_grants=true        
        )
}}

---- SRC LAYER ----
WITH
SRC_gp             as ( SELECT ITEM, LOAD_DTS, FBIN_CATEGORY_I, FBIN_CATEGORY_II, FBIN_CATEGORY_III, CATEGORY_LEADER_NAME
                                , DIRECTOR_NAME, OP_CO, BUSINESS_UNIT, REQUESTOR_EMAIL FROM {{ ref('v_psa_stg_item_sourcing_category_v2') }} as SRC 
                        WHERE (OP_CO IS NOT NULL AND ITEM IS NOT NULL)
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY OP_CO, ITEM ORDER BY LOAD_DTS desc) )

/*
SRC_gp             as ( SELECT * FROM staging.v_psa_stg_item_sourcing_category_v2 )
*/
---- LOGIC LAYER ----

, LOGIC_gp as (
    SELECT
        upper(OP_CO)                                                 as                                              OP_CO
      , ITEM
      , upper(BUSINESS_UNIT)                                         as                                      BUSINESS_UNIT
      , upper(FBIN_CATEGORY_I)                                       as                                    FBIN_CATEGORY_I
      , upper(FBIN_CATEGORY_II)                                      as                                   FBIN_CATEGORY_II
      , upper(FBIN_CATEGORY_III)                                     as                                  FBIN_CATEGORY_III
      , upper(CATEGORY_LEADER_NAME)                                  as                               CATEGORY_LEADER_NAME
      , upper(DIRECTOR_NAME)                                         as                                      DIRECTOR_NAME
      , LOAD_DTS
      , REQUESTOR_EMAIL                                              as                                    REQUESTOR_EMAIL
    FROM SRC_gp
)
---- RENAME LAYER ----

, RENAME_gp as (
    SELECT
        OP_CO
      , ITEM
      , BUSINESS_UNIT
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , CATEGORY_LEADER_NAME
      , DIRECTOR_NAME
      , LOAD_DTS
      , REQUESTOR_EMAIL
    FROM LOGIC_gp
)
---- FILTER LAYER ----

, FILTER_gp as (
    SELECT *
    FROM RENAME_gp
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_gp
)

---- FINAL LAYER ----
SELECT
          OP_CO
        , ITEM
        , BUSINESS_UNIT
        , FBIN_CATEGORY_I
        , FBIN_CATEGORY_II
        , FBIN_CATEGORY_III
        , CATEGORY_LEADER_NAME
        , DIRECTOR_NAME
        , REQUESTOR_EMAIL
        , LOAD_DTS
FROM JOIN_RESULT
