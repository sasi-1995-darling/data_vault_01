---- SRC LAYER ----
WITH
SRC_SITMCLSGP      as ( SELECT * FROM {{ ref('v_psa_stg_item_class__tt_gp') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SITMCLSGP      as ( SELECT * FROM STAGING.v_psa_stg_item_class__tt_gp )
*/
---- LOGIC LAYER ----

, LOGIC_SITMCLSGP as (
    SELECT
        ITEM_CLASS_BK
      , ITMCLSCD                                                     as                                    ITEM_CLASS_CODE
      , ITMCLSDC                                                     as                                    ITEM_CLASS_DESC
      , DEFLTCLS                                                     as                                      DEFAULT_CLASS
      , NOTEINDX                                                     as                                         NOTE_INDEX
      , ITEMTYPE                                                     as                                       ITEM_TYPE_ID
      , ITMTRKOP                                                     as                               ITEM_TRACKING_OPT_ID
      , KPERHIST                                                     as                                KEEP_PERIOD_HISTORY
      , KPTRXHST                                                     as                                   KEEP_TRX_HISTORY
      , KPCALHST                                                     as                              KEEP_CALENDAR_HISTORY
      , KPDSTHST                                                     as                          KEEP_DISTRIBUTION_HISTORY
      , ALWBKORD                                                     as                                  ALLOW_BACK_ORDERS
      , ITMGEDSC                                                     as                           ITEM_GENERIC_DESCRIPTION
      , TAXOPTNS                                                     as                                         TAX_OPT_ID
      , PURCHASE_TAX_OPTIONS
      , UOMSCHDL                                                     as                                       UOM_SCHEDULE
      , VCTNMTHD                                                     as                                VALUATION_METHOD_ID
      , DECPLQTY                                                     as                                DECIMAL_PLACES_QTYS
      , IVIVINDX                                                     as                                           IV_INDEX
      , IVIVOFIX                                                     as                                    IV_OFFSET_INDEX
      , IVCOGSIX                                                     as                                      IV_COGS_INDEX
      , IVSLSIDX                                                     as                                     IV_SALES_INDEX
      , IVSLDSIX                                                     as                           IV_SALES_DISCOUNTS_INDEX
      , IVSLRNIX                                                     as                             IV_SALES_RETURNS_INDEX
      , IVINUSIX                                                     as                                    IV_IN_USE_INDEX
      , IVINSVIX                                                     as                                IV_IN_SERVICE_INDEX
      , IVDMGIDX                                                     as                                   IV_DAMAGED_INDEX
      , IVVARIDX                                                     as                                 IV_VARIANCES_INDEX
      , DPSHPIDX                                                     as                                    DROP_SHIP_INDEX
      , PURPVIDX                                                     as                           PURCHASE_PRICE_VAR_INDEX
      , UPPVIDX                                                      as                UNREALIZED_PURCHASE_PRICE_VAR_INDEX
      , IVRETIDX                                                     as                            INVENTORY_RETURNS_INDEX
      , ASMVRIDX                                                     as                            ASSEMBLY_VARIANCE_INDEX
      , PRCLEVEL                                                     as                                        PRICE_LEVEL
      , PRICEGROUP                                                   as                                        PRICE_GROUP
      , PRICMTHD                                                     as                                    PRICE_METHOD_ID
      , REVALUE_INVENTORY
      , TOLERANCE_PERCENTAGE
      , STTSTCLVLPRCNTG                                              as                       STATISTICAL_VALUE_PERCENTAGE
      , INCLUDEINDP                                                  as                         INCLUDE_IN_DEMAND_PLANNING
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_SITMCLSGP
)
---- RENAME LAYER ----

, RENAME_SITMCLSGP as (
    SELECT
        ITEM_CLASS_BK
      , ITEM_CLASS_CODE
      , ITEM_CLASS_DESC
      , DEFAULT_CLASS
      , NOTE_INDEX
      , ITEM_TYPE_ID
      , ITEM_TRACKING_OPT_ID
      , KEEP_PERIOD_HISTORY
      , KEEP_TRX_HISTORY
      , KEEP_CALENDAR_HISTORY
      , KEEP_DISTRIBUTION_HISTORY
      , ALLOW_BACK_ORDERS
      , ITEM_GENERIC_DESCRIPTION
      , TAX_OPT_ID
      , PURCHASE_TAX_OPTIONS
      , UOM_SCHEDULE
      , VALUATION_METHOD_ID
      , DECIMAL_PLACES_QTYS
      , IV_INDEX
      , IV_OFFSET_INDEX
      , IV_COGS_INDEX
      , IV_SALES_INDEX
      , IV_SALES_DISCOUNTS_INDEX
      , IV_SALES_RETURNS_INDEX
      , IV_IN_USE_INDEX
      , IV_IN_SERVICE_INDEX
      , IV_DAMAGED_INDEX
      , IV_VARIANCES_INDEX
      , DROP_SHIP_INDEX
      , PURCHASE_PRICE_VAR_INDEX
      , UNREALIZED_PURCHASE_PRICE_VAR_INDEX
      , INVENTORY_RETURNS_INDEX
      , ASSEMBLY_VARIANCE_INDEX
      , PRICE_LEVEL
      , PRICE_GROUP
      , PRICE_METHOD_ID
      , REVALUE_INVENTORY
      , TOLERANCE_PERCENTAGE
      , STATISTICAL_VALUE_PERCENTAGE
      , INCLUDE_IN_DEMAND_PLANNING
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_SITMCLSGP
)
---- FILTER LAYER ----

, FILTER_SITMCLSGP as (
    SELECT *
    FROM RENAME_SITMCLSGP
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SITMCLSGP
)

---- FINAL LAYER ----
SELECT
          ITEM_CLASS_BK
        , ITEM_CLASS_CODE
        , ITEM_CLASS_DESC
        , DEFAULT_CLASS
        , NOTE_INDEX
        , ITEM_TYPE_ID
        , ITEM_TRACKING_OPT_ID
        , KEEP_PERIOD_HISTORY
        , KEEP_TRX_HISTORY
        , KEEP_CALENDAR_HISTORY
        , KEEP_DISTRIBUTION_HISTORY
        , ALLOW_BACK_ORDERS
        , ITEM_GENERIC_DESCRIPTION
        , TAX_OPT_ID
        , PURCHASE_TAX_OPTIONS
        , UOM_SCHEDULE
        , VALUATION_METHOD_ID
        , DECIMAL_PLACES_QTYS
        , IV_INDEX
        , IV_OFFSET_INDEX
        , IV_COGS_INDEX
        , IV_SALES_INDEX
        , IV_SALES_DISCOUNTS_INDEX
        , IV_SALES_RETURNS_INDEX
        , IV_IN_USE_INDEX
        , IV_IN_SERVICE_INDEX
        , IV_DAMAGED_INDEX
        , IV_VARIANCES_INDEX
        , DROP_SHIP_INDEX
        , PURCHASE_PRICE_VAR_INDEX
        , UNREALIZED_PURCHASE_PRICE_VAR_INDEX
        , INVENTORY_RETURNS_INDEX
        , ASSEMBLY_VARIANCE_INDEX
        , PRICE_LEVEL
        , PRICE_GROUP
        , PRICE_METHOD_ID
        , REVALUE_INVENTORY
        , TOLERANCE_PERCENTAGE
        , STATISTICAL_VALUE_PERCENTAGE
        , INCLUDE_IN_DEMAND_PLANNING
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ITEM_CLASS_BK = JOIN_RESULT.ITEM_CLASS_BK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}