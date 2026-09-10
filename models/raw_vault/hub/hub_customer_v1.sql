---- SRC LAYER ----
WITH
SRC_SCUSTLR        as ( SELECT BKCC, CUSTOMER_BK, CUSTOMER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_customer__lrsn_psft') }} as SRC  ),
SRC_SCGRPLR        as ( SELECT BKCC, CUSTOMER_BK, CUSTOMER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_cust_cgrp__lrsn_psft') }} as SRC  ),
SRC_SBIHSOLD       as ( SELECT BKCC, CUSTOMER_SOLDTO_HK, LOAD_DTS, REC_SRC, SOLD_TO_CUSTOMER_BK  FROM {{ ref('v_psa_stg_bi_hdr__lrsn_psft') }} as SRC  ),
SRC_SCUSTMN        as ( SELECT BKCC, CUSTOMER_BK, CUSTOMER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_customer__moen_sap') }} as SRC  ),
SRC_SSHIPMN        as ( SELECT BKCC, CUSTOMER_BK, CUSTOMER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_shipment__moen_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CUSTOMER_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_SINPMN         as ( SELECT BKCC, CUSTOMER_BK, CUSTOMER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_shipment_inputs__moen_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CUSTOMER_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_SCUSTFB        as ( SELECT BKCC, CUSTOMER_BK, CUSTOMER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_customer__fib_ocf') }} as SRC  ),
SRC_SINVFB         as ( SELECT BKCC, CUSTOMER_SOLDTO_BK, CUSTOMER_SOLDTO_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_invoice_header__fib_ocf') }} as SRC  ),
SRC_SCUSTPARTYML   as ( SELECT BKCC, CUSTOMER_BK, CUSTOMER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_customer_party__ml_ebs') }} as SRC  ),
SRC_SCUSTML         as ( SELECT BKCC, CUSTOMER_BK, CUSTOMER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_customer__ml_ebs') }} as SRC  ),
SRC_MRPLINE        as ( SELECT BKCC, CUSTOMER_BK, CUSTOMER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_mrp_lines__winn_sap') }} as SRC  ),
SRC_CUSTSLSMN      as ( SELECT BKCC, CUSTOMER_BK, CUSTOMER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_customer_sales_master__winn_sap') }} as SRC  ),
SRC_CE1NEW4        as ( SELECT BKCC, CUSTOMER_BK, CUSTOMER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_copa_sales__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CUSTOMER_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_AZCOPA         as ( {% if not is_incremental() %} SELECT BKCC, CUSTOMER_BK, CUSTOMER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_copa_sales_history__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CUSTOMER_BK ORDER BY ZEXTRACTDATE ))=1 {% endif %}
                        {% if is_incremental() %} SELECT * FROM {{ this }} WHERE FALSE {% endif %}
                        /*To improve efficiency and performance; scan and load historical SAP BW AZCOPA table only on initial run */ ),
SRC_HOFRSALES      as ( SELECT BKCC, CUSTOMER_BK, CUSTOMER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_legacy_hofrus_sales__hofr_ecl') }} as SRC  ),
SRC_ZSERVLEVEL     as ( SELECT BKCC, CUSTOMER_BK, CUSTOMER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_service_levels__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CUSTOMER_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_INVENTORY      as ( SELECT BKCC, CUSTOMER_BK, CUSTOMER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_goods_movement__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CUSTOMER_BK ORDER BY LOAD_DTS ))=1 ),
SRC_INVENTORY_CUST as ( SELECT BKCC, CUSTOMER_SHIP_LOCATION_BK, CUSTOMER_SHIP_LOCATION_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_goods_movement__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CUSTOMER_SHIP_LOCATION_BK ORDER BY LOAD_DTS ))=1 ),
SRC_SHOPORDHDR     as ( SELECT BKCC, CUSTOMER_BK, CUSTOMER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_dtc_order_header__winn_shopify') }} as SRC  ),
SRC_SINVLNWINN    as ( SELECT BKCC, CUSTOMER_BK, CUSTOMER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_sales_invoice_line__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CUSTOMER_BK ORDER BY LOAD_DTS ))=1 )

/*
SRC_SCUSTLR        as ( SELECT * FROM STAGING.v_psa_stg_customer__lrsn_psft )
SRC_SCGRPLR        as ( SELECT * FROM STAGING.v_psa_stg_cust_cgrp__lrsn_psft )
SRC_SBIHSOLD       as ( SELECT * FROM STAGING.v_psa_stg_bi_hdr__lrsn_psft )
SRC_SCUSTMN        as ( SELECT * FROM STAGING.v_psa_stg_customer__moen_sap )
SRC_SSHIPMN        as ( SELECT * FROM STAGING.v_psa_stg_shipment__moen_sap )
SRC_SINPMN         as ( SELECT * FROM STAGING.v_psa_stg_shipment_inputs__moen_sap )
SRC_SCUSTFB        as ( SELECT * FROM STAGING.v_psa_stg_customer__fib_ocf )
SRC_SINVFB         as ( SELECT * FROM STAGING.v_psa_stg_invoice_header__fib_ocf )
SRC_SCUSTPARTYML   as ( SELECT * FROM STAGING.v_psa_stg_customer_party__ml_ebs )
SRC_SCUSTML         as ( SELECT * FROM STAGING.v_psa_stg_customer__ml_ebs )
SRC_MRPLINE        as ( SELECT * FROM STAGING.v_psa_stg_mrp_lines__winn_sap )
SRC_CUSTSLSMN      as ( SELECT * FROM STAGING.v_psa_stg_customer_sales_master__winn_sap )
SRC_CE1NEW4        as ( SELECT * FROM STAGING.v_psa_stg_copa_sales__winn_sap )
SRC_AZCOPA         as ( SELECT * FROM STAGING.v_psa_stg_copa_sales_history__winn_sap )
SRC_HOFRSALES      as ( SELECT * FROM STAGING.v_psa_stg_legacy_hofrus_sales__hofr_ecl )
SRC_ZSERVLEVEL     as ( SELECT * FROM STAGING.v_psa_stg_service_levels__winn_sap )
SRC_INVENTORY      as ( SELECT * FROM STAGING.v_psa_stg_goods_movement__winn_sap )
SRC_INVENTORY_CUST as ( SELECT * FROM STAGING.v_psa_stg_goods_movement__winn_sap )
SRC_SHOPORDHDR     as ( SELECT * FROM STAGING.v_psa_stg_dtc_order_header__winn_shopify )
SRC_SINVLNWINN    as ( SELECT * FROM STAGING.v_psa_stg_sales_invoice_line__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_SCUSTLR as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SCUSTLR
)

, LOGIC_SCGRPLR as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SCGRPLR
)

, LOGIC_SBIHSOLD as (
    SELECT
        CUSTOMER_SOLDTO_HK                                           as                                        CUSTOMER_HK
      , SOLD_TO_CUSTOMER_BK                                          as                                        CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SBIHSOLD
)

, LOGIC_SCUSTMN as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SCUSTMN
)

, LOGIC_SSHIPMN as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SSHIPMN
)

, LOGIC_SINPMN as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SINPMN
)

, LOGIC_SCUSTFB as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SCUSTFB
)

, LOGIC_SINVFB as (
    SELECT
        CUSTOMER_SOLDTO_HK                                           as                                        CUSTOMER_HK
      , CUSTOMER_SOLDTO_BK                                           as                                        CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SINVFB
)

, LOGIC_SCUSTPARTYML  as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SCUSTPARTYML 
)

, LOGIC_SCUSTML         as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SCUSTML        
)

, LOGIC_MRPLINE        as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_MRPLINE       
)

, LOGIC_CUSTSLSMN as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_CUSTSLSMN
)

, LOGIC_CE1NEW4 as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_CE1NEW4
)

, LOGIC_AZCOPA as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_AZCOPA
)

, LOGIC_HOFRSALES as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_HOFRSALES
)

, LOGIC_ZSERVLEVEL as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ZSERVLEVEL
)

, LOGIC_INVENTORY as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_INVENTORY
)

, LOGIC_INVENTORY_CUST as (
    SELECT
        CUSTOMER_SHIP_LOCATION_HK
      , CUSTOMER_SHIP_LOCATION_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_INVENTORY_CUST
)

, LOGIC_SHOPORDHDR as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SHOPORDHDR
)

, LOGIC_SINVLNWINN as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SINVLNWINN
)
---- RENAME LAYER ----

, RENAME_SCUSTLR as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SCUSTLR
)

, RENAME_SCGRPLR as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SCGRPLR
)

, RENAME_SBIHSOLD as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SBIHSOLD
)

, RENAME_SCUSTMN as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SCUSTMN
)

, RENAME_SSHIPMN as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SSHIPMN
)

, RENAME_SINPMN as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SINPMN
)

, RENAME_SCUSTFB as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SCUSTFB
)

, RENAME_SINVFB as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SINVFB
)

, RENAME_SCUSTPARTYML  as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SCUSTPARTYML 
)

, RENAME_SCUSTML         as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SCUSTML        
)

, RENAME_MRPLINE        as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_MRPLINE       
)

, RENAME_CUSTSLSMN as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_CUSTSLSMN
)

, RENAME_CE1NEW4 as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_CE1NEW4
)

, RENAME_AZCOPA as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_AZCOPA
)

, RENAME_HOFRSALES as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_HOFRSALES
)

, RENAME_ZSERVLEVEL as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ZSERVLEVEL
)

, RENAME_INVENTORY as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_INVENTORY
)

, RENAME_INVENTORY_CUST as (
    SELECT
        CUSTOMER_SHIP_LOCATION_HK as  CUSTOMER_HK
      , CUSTOMER_SHIP_LOCATION_BK as  CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_INVENTORY_CUST
)

, RENAME_SHOPORDHDR as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SHOPORDHDR
)

, RENAME_SINVLNWINN as (
    SELECT
        CUSTOMER_HK
      , CUSTOMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SINVLNWINN
)
---- FILTER LAYER ----

, FILTER_SCUSTLR as (
    SELECT *
    FROM RENAME_SCUSTLR
)

, FILTER_SCGRPLR as (
    SELECT *
    FROM RENAME_SCGRPLR
)

, FILTER_SBIHSOLD as (
    SELECT *
    FROM RENAME_SBIHSOLD
)

, FILTER_SCUSTMN as (
    SELECT *
    FROM RENAME_SCUSTMN
)

, FILTER_SSHIPMN as (
    SELECT *
    FROM RENAME_SSHIPMN
)

, FILTER_SINPMN as (
    SELECT *
    FROM RENAME_SINPMN
)

, FILTER_SCUSTFB as (
    SELECT *
    FROM RENAME_SCUSTFB
)

, FILTER_SINVFB as (
    SELECT *
    FROM RENAME_SINVFB
)

, FILTER_SCUSTPARTYML  as (
    SELECT *
    FROM RENAME_SCUSTPARTYML 
)

, FILTER_SCUSTML         as (
    SELECT *
    FROM RENAME_SCUSTML        
)

, FILTER_MRPLINE        as (
    SELECT *
    FROM RENAME_MRPLINE       
)

, FILTER_CUSTSLSMN as (
    SELECT *
    FROM RENAME_CUSTSLSMN
)

, FILTER_CE1NEW4 as (
    SELECT *
    FROM RENAME_CE1NEW4
)

, FILTER_AZCOPA as (
    SELECT *
    FROM RENAME_AZCOPA
)

, FILTER_HOFRSALES as (
    SELECT *
    FROM RENAME_HOFRSALES
)

, FILTER_ZSERVLEVEL as (
    SELECT *
    FROM RENAME_ZSERVLEVEL
)

, FILTER_INVENTORY as (
    SELECT *
    FROM RENAME_INVENTORY
)

, FILTER_INVENTORY_CUST as (
    SELECT *
    FROM RENAME_INVENTORY_CUST
)

, FILTER_SHOPORDHDR as (
    SELECT *
    FROM RENAME_SHOPORDHDR
)

, FILTER_SINVLNWINN as (
    SELECT *
    FROM RENAME_SINVLNWINN
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_SCUSTLR
    UNION ALL
    SELECT * FROM FILTER_SCGRPLR
    UNION ALL
    SELECT * FROM FILTER_SBIHSOLD
    UNION ALL
    SELECT * FROM FILTER_SCUSTMN
    UNION ALL
    SELECT * FROM FILTER_SSHIPMN
    UNION ALL
    SELECT * FROM FILTER_SINPMN
    UNION ALL
    SELECT * FROM FILTER_SCUSTFB
    UNION ALL
    SELECT * FROM FILTER_SINVFB
    UNION ALL
    SELECT * FROM FILTER_SCUSTPARTYML 
    UNION ALL
    SELECT * FROM FILTER_SCUSTML        
    UNION ALL
    SELECT * FROM FILTER_MRPLINE       
    UNION ALL
    SELECT * FROM FILTER_CUSTSLSMN
    UNION ALL
    SELECT * FROM FILTER_CE1NEW4
    UNION ALL
    SELECT * FROM FILTER_AZCOPA
    UNION ALL
    SELECT * FROM FILTER_HOFRSALES
    UNION ALL
    SELECT * FROM FILTER_ZSERVLEVEL
    UNION ALL
    SELECT * FROM FILTER_INVENTORY
    UNION ALL
    SELECT * FROM FILTER_INVENTORY_CUST
    UNION ALL
    SELECT * FROM FILTER_SHOPORDHDR
    UNION ALL
    SELECT * FROM FILTER_SINVLNWINN
)

---- FINAL LAYER ----
SELECT
          CUSTOMER_HK
        , CUSTOMER_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.CUSTOMER_HK = JOIN_RESULT.CUSTOMER_HK
)
{% endif %}
QUALIFY 1= ROW_NUMBER() OVER (PARTITION BY CUSTOMER_BK, BKCC ORDER BY LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS CUSTOMER_HK,
GR.VALUE::text AS CUSTOMER_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
