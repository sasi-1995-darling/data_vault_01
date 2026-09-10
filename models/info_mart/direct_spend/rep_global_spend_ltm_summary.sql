---- SRC LAYER ----
WITH
SRC_FGSD           as ( SELECT BKCC, ITEM_BK, ITEM_HK, OPCO, POSTING_DATE__YYYYMMDD, PO_HEADER_ID, PO_ITEM_UOM, REC_SRC, SPEND_USD, SPEND_VOLUME, SUPPLIER_HK, SUPPLIER_NAME_CHILD, SUPPLIER_NAME_PARENT, SUPPLIER_NUMBER_CHILD, SUPPLIER_NUMBER_PARENT FROM {{ ref('fact_global_spend_detail') }} as SRC 
                        /* Filter last 12months  */
                        WHERE to_DATE(POSTING_DATE__YYYYMMDD::TEXT,'YYYYMMDD') >= DATEADD(month, -12, GETDATE())
                        
                         ),
SRC_DITM           as ( SELECT ITEM_ID, ITEM_TITLE FROM {{ ref('dim_item_fbin') }} as SRC  )

/*
SRC_FGSD           as ( SELECT * FROM BUS_VAULT.FACT_GLOBAL_SPEND_DETAIL )
SRC_DITM           as ( SELECT * FROM BUS_VAULT.DIM_ITEM_FBIN )
*/
---- LOGIC LAYER ----

, LOGIC_FGSD as (
    SELECT
        ITEM_BK
      , OPCO
      , SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , PO_ITEM_UOM                                                  as                                                UOM
      , ITEM_HK
      , SUPPLIER_HK
      , BKCC
      , REC_SRC
      , ROW_NUMBER() OVER (PARTITION BY SUPPLIER_HK, ITEM_HK, OPCO,PO_ITEM_UOM ORDER BY POSTING_DATE__YYYYMMDD DESC, PO_HEADER_ID ) as                                            PO_RANK
      , POSTING_DATE__YYYYMMDD
      , PO_HEADER_ID
      , SPEND_USD
      , SPEND_VOLUME
    FROM SRC_FGSD
)

, LOGIC_DITM as (
    SELECT
        ITEM_TITLE                                                   as                                   ITEM_DESCRIPTION
      , ITEM_ID
    FROM SRC_DITM
)
---- RENAME LAYER ----

, RENAME_FGSD as (
    SELECT
        ITEM_BK
      , OPCO
      , SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , UOM
      , ITEM_HK
      , SUPPLIER_HK
      , BKCC
      , REC_SRC
      , PO_RANK
      , POSTING_DATE__YYYYMMDD
      , PO_HEADER_ID
      , SPEND_USD
      , SPEND_VOLUME
    FROM LOGIC_FGSD
)

, RENAME_DITM as (
    SELECT
        ITEM_DESCRIPTION
      , ITEM_ID
    FROM LOGIC_DITM
)
---- FILTER LAYER ----

, FILTER_FGSD as (
    SELECT *
    FROM RENAME_FGSD
    WHERE 
/* This filter is to retain spend with Item*/
NOT NULLIF(TRIM(ITEM_BK),'') IS NULL
  and ITEM_BK != '-2' --Optional Ghost Record 
)

, FILTER_DITM as (
    SELECT *
    FROM RENAME_DITM
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_FGSD
    LEFT JOIN FILTER_DITM
        ON FILTER_FGSD.ITEM_HK = FILTER_DITM.ITEM_ID
)

---- FINAL LAYER ----
SELECT
          ITEM_BK
        , ITEM_DESCRIPTION
        , OPCO
        , SUPPLIER_NUMBER_PARENT
        , SUPPLIER_NAME_PARENT
        , SUPPLIER_NUMBER_CHILD
        , SUPPLIER_NAME_CHILD
        , SUM(SPEND_USD)                                               as TOTAL_LTM_SPEND_USD
        , SUM(SPEND_VOLUME)                                            as TOTAL_LTM_SPEND_VOLUME
        , MIN_BY(SPEND_USD,PO_RANK)                                    as LATEST_SPEND_USD
        , MIN_BY(SPEND_VOLUME,PO_RANK)                                 as LATEST_SPEND_VOLUME
        , UOM
        , ITEM_HK
        , SUPPLIER_HK
        , BKCC
        , REC_SRC
FROM JOIN_RESULT
GROUP BY ALL