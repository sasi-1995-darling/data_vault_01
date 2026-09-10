---- SRC LAYER ----
WITH
SRC_gp             as ( SELECT BKCC, CUSTOMER_SKU_HK, FIBERON_ITEM_NUM_HK, FIBERON_PART_NUM_HK, HASHDIFF, LOAD_DTS, MANUF_PART_NUMBER, ORACLE_ITEM_ID, REC_SRC, SKU FROM {{ ref('v_psa_stg_pos_cross_ref__fiberon_hd_askuity') }} as SRC 
                        qualify row_number() over(partition by manuf_part_number,sku,load_dts order by load_dts desc)=1 )

/*
SRC_gp             as ( SELECT * FROM staging.v_psa_stg_pos_cross_ref__fiberon_hd_askuity )
*/
---- LOGIC LAYER ----

, LOGIC_gp as (
    SELECT
        CUSTOMER_SKU_HK
      , FIBERON_PART_NUM_HK
      , FIBERON_ITEM_NUM_HK
      , MANUF_PART_NUMBER                                            as                             DERV_MANUF_PART_NUMBER
      , SKU                                                          as                                           DERV_SKU
      , LOAD_DTS
      , ORACLE_ITEM_ID
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_gp
)
---- RENAME LAYER ----

, RENAME_gp as (
    SELECT
        CUSTOMER_SKU_HK
      , FIBERON_PART_NUM_HK
      , FIBERON_ITEM_NUM_HK
      , DERV_MANUF_PART_NUMBER
      , DERV_SKU
      , LOAD_DTS
      , ORACLE_ITEM_ID
      , REC_SRC
      , BKCC
      , HASHDIFF
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
          CUSTOMER_SKU_HK
        , FIBERON_PART_NUM_HK
        , FIBERON_ITEM_NUM_HK
        , coalesce(nullif(trim(DERV_MANUF_PART_NUMBER), ''), 'N/A')    as MANUF_PART_NUMBER
        , coalesce(nullif(trim(DERV_SKU), ''), 'N/A')                  as SKU
        , LOAD_DTS
        , ORACLE_ITEM_ID
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
