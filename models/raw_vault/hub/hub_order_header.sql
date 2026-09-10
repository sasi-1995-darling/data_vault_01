
---- SRC LAYER ----
WITH
SRC_OHMLEBS        as ( SELECT BKCC, LOAD_DTS, ORDER_HEADER_BK, ORDER_HEADER_HK, REC_SRC FROM {{ ref('v_psa_stg_order_header__ml_ebs') }} as SRC  ),
SRC_OLMLEBS        as ( SELECT BKCC, LOAD_DTS, ORDER_HEADER_BK, ORDER_HEADER_HK, REC_SRC FROM {{ ref('v_psa_stg_order_line__ml_ebs') }} as SRC 
                         QUALIFY (ROW_NUMBER() OVER(PARTITION BY ORDER_HEADER_BK ORDER BY _FIVETRAN_SYNCED  ))=1 ),
SRC_VBAK           as ( SELECT BKCC, LOAD_DTS, ORDER_HEADER_BK, ORDER_HEADER_HK, REC_SRC FROM {{ ref('v_psa_stg_order_header__winn_sap') }} as SRC  ),
SRC_CE1NEW4        as ( SELECT BKCC, LOAD_DTS, ORDER_HEADER_BK, ORDER_HEADER_HK, REC_SRC FROM {{ ref('v_psa_stg_copa_sales__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ORDER_HEADER_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_AZCOPA         as ( {% if not is_incremental() %} SELECT BKCC, LOAD_DTS, ORDER_HEADER_BK, ORDER_HEADER_HK, REC_SRC FROM {{ ref('v_psa_stg_copa_sales_history__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ORDER_HEADER_BK ORDER BY ZEXTRACTDATE ))=1 {% endif %} 
                        {% if is_incremental() %} SELECT * FROM {{ this }} WHERE FALSE {% endif %}
                        /*To improve efficiency and performance; scan and load historical SAP BW AZCOPA table only on initial run */ ),
SRC_ZSERVLEVEL     as ( SELECT BKCC, LOAD_DTS, ORDER_HEADER_BK, ORDER_HEADER_HK, REC_SRC FROM {{ ref('v_psa_stg_service_levels__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ORDER_HEADER_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_RESERVATION    as ( SELECT BKCC, LOAD_DTS, ORDER_HEADER_BK, ORDER_HEADER_HK, REC_SRC FROM {{ ref('v_psa_stg_reservation_line__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ORDER_HEADER_BK ORDER BY GLCHANGETIME  ))=1 ),
SRC_SHOPORDLN      as ( SELECT BKCC, LOAD_DTS, ORDER_HEADER_BK, ORDER_HEADER_HK, REC_SRC FROM {{ ref('v_psa_stg_dtc_order_line__winn_shopify') }} as SRC  ),
SRC_SHOPORDHDR     as ( SELECT BKCC, LOAD_DTS, ORDER_HEADER_BK, ORDER_HEADER_HK, REC_SRC FROM {{ ref('v_psa_stg_dtc_order_header__winn_shopify') }} as SRC ),
SRC_VBUK           as ( SELECT BKCC, LOAD_DTS, ORDER_HEADER_BK, ORDER_HEADER_HK, REC_SRC FROM {{ ref('v_psa_stg_order_header_status__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ORDER_HEADER_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_LIPS           as ( SELECT BKCC, LOAD_DTS, ORDER_HEADER_BK, ORDER_HEADER_HK, REC_SRC FROM {{ ref('v_psa_stg_delivery_line_detail__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ORDER_HEADER_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_VBAP           as ( SELECT BKCC, LOAD_DTS, ORDER_HEADER_BK, ORDER_HEADER_HK, REC_SRC FROM {{ ref('v_psa_stg_order_item__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ORDER_HEADER_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_VBEP           as ( SELECT BKCC, LOAD_DTS, ORDER_HEADER_BK, ORDER_HEADER_HK, REC_SRC FROM {{ ref('v_psa_stg_sales_order_item_scheduled_shipping__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ORDER_HEADER_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_OHTTE21        as ( SELECT BKCC, LOAD_DTS, ORDER_HEADER_BK, ORDER_HEADER_HK, REC_SRC FROM {{ref('v_psa_stg_order_header__tt_e21') }}  as  SRC ),

SRC_SAPVKBD        as ( SELECT BKCC, LOAD_DTS, ORDER_HEADER_BK, ORDER_HEADER_HK, REC_SRC FROM {{ref('v_psa_stg_business_data__winn_sap') }}  as  SRC
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ORDER_HEADER_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_SHOPTAG        as ( SELECT BKCC, LOAD_DTS, ORDER_HEADER_BK, ORDER_HEADER_HK, REC_SRC FROM {{ref('v_psa_stg_dtc_order_tag__winn_shopify') }}  as  SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ORDER_HEADER_BK ORDER BY LOAD_DTS ))=1),
SRC_SHOPDISCOUNT        as ( SELECT BKCC, LOAD_DTS, ORDER_HEADER_BK, ORDER_HEADER_HK, REC_SRC FROM {{ref('v_psa_stg_dtc_order_discount__winn_shopify') }}  as  SRC
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ORDER_HEADER_BK ORDER BY LOAD_DTS ))=1) 

/*
SRC_OHMLEBS        as ( SELECT * FROM STAGING.v_psa_stg_order_header__ml_ebs )
SRC_OLMLEBS        as ( SELECT * FROM STAGING.v_psa_stg_order_line__ml_ebs )
SRC_VBAK           as ( SELECT * FROM STAGING.v_psa_stg_order_header__winn_sap )
SRC_CE1NEW4        as ( SELECT * FROM STAGING.v_psa_stg_copa_sales__winn_sap )
SRC_AZCOPA         as ( SELECT * FROM STAGING.v_psa_stg_copa_sales_history__winn_sap )
SRC_ZSERVLEVEL     as ( SELECT * FROM STAGING.v_psa_stg_service_levels__winn_sap )
SRC_RESERVATION    as ( SELECT * FROM STAGING.v_psa_stg_reservation_line__winn_sap )
SRC_SHOPORDLN      as ( SELECT * FROM STAGING.v_psa_stg_dtc_order_line__winn_shopify )
SRC_SHOPORDHDR     as ( SELECT * FROM STAGING.v_psa_stg_dtc_order_header__winn_shopify )
SRC_VBUK           as ( SELECT * FROM STAGING.v_psa_stg_order_header_status__winn_sap )
SRC_LIPS           as ( SELECT * FROM STAGING.v_psa_stg_delivery_line_detail__winn_sap )
SRC_VBAP           as ( SELECT * FROM STAGING.v_psa_stg_order_item__winn_sap )
SRC_VBEP           as ( SELECT * FROM STAGING.v_psa_stg_sales_order_item_scheduled_shipping__winn_sap )
SRC_OHTTE21        as ( SELECT * FROM STAGING.v_psa_stg_order_header__tt_e21)
*/
---- LOGIC LAYER ----

, LOGIC_OHMLEBS as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_OHMLEBS
)

, LOGIC_OLMLEBS as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_OLMLEBS
)

, LOGIC_VBAK as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_VBAK
)

, LOGIC_CE1NEW4 as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_CE1NEW4
)

, LOGIC_AZCOPA as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_AZCOPA
)

, LOGIC_ZSERVLEVEL as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ZSERVLEVEL
)

, LOGIC_RESERVATION as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_RESERVATION
)

, LOGIC_SHOPORDLN as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SHOPORDLN
)

, LOGIC_SHOPORDHDR as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SHOPORDHDR
)

, LOGIC_VBUK as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_VBUK
)

, LOGIC_LIPS as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_LIPS
)

, LOGIC_VBAP as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_VBAP
)

, LOGIC_VBEP as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_VBEP
)

, LOGIC_OHTTE21 as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_OHTTE21
)

, LOGIC_SAPVKBD as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SAPVKBD
)
, LOGIC_SHOPTAG as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SHOPTAG
)
, LOGIC_SHOPDISCOUNT as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SHOPDISCOUNT
)
---- RENAME LAYER ----

, RENAME_OHMLEBS as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_OHMLEBS
)

, RENAME_OLMLEBS as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_OLMLEBS
)

, RENAME_VBAK as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_VBAK
)

, RENAME_CE1NEW4 as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_CE1NEW4
)

, RENAME_AZCOPA as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_AZCOPA
)

, RENAME_ZSERVLEVEL as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ZSERVLEVEL
)

, RENAME_RESERVATION as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_RESERVATION
)

, RENAME_SHOPORDLN as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SHOPORDLN
)

, RENAME_SHOPORDHDR as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SHOPORDHDR
)

, RENAME_VBUK as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_VBUK
)

, RENAME_LIPS as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_LIPS
)

, RENAME_VBAP as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_VBAP
)

, RENAME_VBEP as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_VBEP
)

, RENAME_OHTTE21 as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_OHTTE21
)

, RENAME_SAPVKBD as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SAPVKBD
)
, RENAME_SHOPTAG as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SHOPTAG
)
, RENAME_SHOPDISCOUNT as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SHOPDISCOUNT
)

---- FILTER LAYER ----

, FILTER_OHMLEBS as (
    SELECT *
    FROM RENAME_OHMLEBS
)

, FILTER_OLMLEBS as (
    SELECT *
    FROM RENAME_OLMLEBS
)

, FILTER_VBAK as (
    SELECT *
    FROM RENAME_VBAK
)

, FILTER_CE1NEW4 as (
    SELECT *
    FROM RENAME_CE1NEW4
)

, FILTER_AZCOPA as (
    SELECT *
    FROM RENAME_AZCOPA
)

, FILTER_ZSERVLEVEL as (
    SELECT *
    FROM RENAME_ZSERVLEVEL
)

, FILTER_RESERVATION as (
    SELECT *
    FROM RENAME_RESERVATION
)

, FILTER_SHOPORDLN as (
    SELECT *
    FROM RENAME_SHOPORDLN
)

, FILTER_SHOPORDHDR as (
    SELECT *
    FROM RENAME_SHOPORDHDR
)

, FILTER_VBUK as (
    SELECT *
    FROM RENAME_VBUK
)

, FILTER_LIPS as (
    SELECT *
    FROM RENAME_LIPS
)

, FILTER_VBAP as (
    SELECT *
    FROM RENAME_VBAP
)

, FILTER_VBEP as (
    SELECT *
    FROM RENAME_VBEP
)

, FILTER_OHTTE21 as (
    SELECT *
    FROM RENAME_OHTTE21
)

, FILTER_SAPVKBD as (
    SELECT *
    FROM RENAME_SAPVKBD
)
, FILTER_SHOPTAG as (
    SELECT *
    FROM RENAME_SHOPTAG
)
, FILTER_SHOPDISCOUNT as (
    SELECT *
    FROM RENAME_SHOPDISCOUNT
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    /*This Jinja logic to intelligently bypass unnecessary full downstream refreshes */
    {% if target.name not in ['default', 'dev'] %}
    SELECT * FROM FILTER_OHMLEBS
    UNION ALL
    SELECT * FROM FILTER_OLMLEBS
    UNION ALL
    SELECT * FROM FILTER_VBAK
    UNION ALL
    SELECT * FROM FILTER_CE1NEW4
    UNION ALL
    SELECT * FROM FILTER_AZCOPA
    UNION ALL
    SELECT * FROM FILTER_ZSERVLEVEL
    UNION ALL
    SELECT * FROM FILTER_RESERVATION
    UNION ALL
    SELECT * FROM FILTER_SHOPORDLN
    UNION ALL
    SELECT * FROM FILTER_SHOPORDHDR
    UNION ALL
    {% endif %}
    SELECT * FROM FILTER_VBUK
    UNION ALL
    SELECT * FROM FILTER_LIPS
    UNION ALL
    SELECT * FROM FILTER_VBAP
    UNION ALL
    SELECT * FROM FILTER_VBEP
    UNION ALL
    SELECT * FROM FILTER_OHTTE21
    UNION ALL
    SELECT * FROM FILTER_SAPVKBD
    UNION ALL
    SELECT * FROM FILTER_SHOPTAG
    UNION ALL
    SELECT * FROM FILTER_SHOPDISCOUNT
)

---- FINAL LAYER ----
SELECT
          ORDER_HEADER_HK
        , ORDER_HEADER_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ORDER_HEADER_HK = JOIN_RESULT.ORDER_HEADER_HK
)
{% endif %}
/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per BKs and BKCC. */
qualify 1 = row_number() over (partition by ORDER_HEADER_BK, BKCC order by LOAD_DTS DESC)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS ORDER_HEADER_HK,
GR.VALUE::text AS ORDER_HEADER_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}