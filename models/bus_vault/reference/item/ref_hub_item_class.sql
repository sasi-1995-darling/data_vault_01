---- SRC LAYER ----
WITH
SRC_SFB            as ( SELECT * FROM {{ ref('v_psa_stg_ref_item_class__fib_ocf') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ITEM_CLASS_BK ORDER BY LOAD_DTS DESC))=1 ),
SRC_SITMCLSGP      as ( SELECT * FROM {{ ref('v_psa_stg_item_class__tt_gp') }} as SRC  )

/*
SRC_SFB            as ( SELECT * FROM STAGING.v_psa_stg_ref_ITEM_CLASS__fib_ocf )
, SRC_SITMCLSGP      as ( SELECT * FROM STAGING.v_psa_stg_item_class__tt_gp )
*/
---- LOGIC LAYER ----

, LOGIC_SFB as (
    SELECT
        ITEM_CLASS_BK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SFB
)

, LOGIC_SITMCLSGP as (
    SELECT
        ITEM_CLASS_BK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SITMCLSGP
)
---- RENAME LAYER ----

, RENAME_SFB as (
    SELECT
        ITEM_CLASS_BK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SFB
)

, RENAME_SITMCLSGP as (
    SELECT
        ITEM_CLASS_BK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SITMCLSGP
)
---- FILTER LAYER ----

, FILTER_SFB as (
    SELECT *
    FROM RENAME_SFB
)

, FILTER_SITMCLSGP as (
    SELECT *
    FROM RENAME_SITMCLSGP
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_SFB
    UNION ALL
    SELECT * FROM FILTER_SITMCLSGP
)

---- FINAL LAYER ----
SELECT
          ITEM_CLASS_BK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ITEM_CLASS_BK = JOIN_RESULT.ITEM_CLASS_BK
)
{% endif %}