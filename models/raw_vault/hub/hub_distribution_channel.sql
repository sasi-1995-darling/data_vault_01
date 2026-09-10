---- SRC LAYER ----
WITH
SRC_s              as ( SELECT BKCC, DISTRIBUTION_CHANNEL_BK, DISTRIBUTION_CHANNEL_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_distribution_channel__winn_sap') }} as SRC  ),
SRC_knvv           as ( SELECT BKCC, DISTRIBUTION_CHANNEL_BK, DISTRIBUTION_CHANNEL_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_customer_sales_master__winn_sap') }} as SRC  ),
SRC_a              as ( SELECT BKCC, DISTRIBUTION_CHANNEL_BK, DISTRIBUTION_CHANNEL_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_goods_movement_storage_location__winn_sap') }} as SRC  ),
SRC_ce1new4        as ( SELECT BKCC, DISTRIBUTION_CHANNEL_BK, DISTRIBUTION_CHANNEL_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_copa_sales__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY DISTRIBUTION_CHANNEL_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_azcopa         as ( {% if not is_incremental() %} SELECT BKCC, DISTRIBUTION_CHANNEL_BK, DISTRIBUTION_CHANNEL_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_copa_sales_history__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY DISTRIBUTION_CHANNEL_BK ORDER BY ZEXTRACTDATE ))=1 {% endif %}
                        {% if is_incremental() %} SELECT * FROM {{ this }} WHERE FALSE {% endif %}
                         /*To improve efficiency and performance; scan and load historical SAP BW AZCOPA table only on initial run */ ),
SRC_hofrsales      as ( SELECT BKCC, DISTRIBUTION_CHANNEL_BK, DISTRIBUTION_CHANNEL_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_legacy_hofrus_sales__hofr_ecl') }} as SRC  ),
SRC_zservlevel     as ( SELECT BKCC, DISTRIBUTION_CHANNEL_BK, DISTRIBUTION_CHANNEL_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_service_levels__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY DISTRIBUTION_CHANNEL_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_demand     as ( SELECT BKCC, DISTRIBUTION_CHANNEL_BK, DISTRIBUTION_CHANNEL_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_demand_planning__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY DISTRIBUTION_CHANNEL_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_demand_2    as ( SELECT BKCC, DISTRIBUTION_CHANNEL_BK, DISTRIBUTION_CHANNEL_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_demand_planning_history__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY DISTRIBUTION_CHANNEL_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_SOL            as ( SELECT BKCC, DISTRIBUTION_CHANNEL_BK, DISTRIBUTION_CHANNEL_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_order_item__winn_sap') }} as SRC
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY DISTRIBUTION_CHANNEL_BK ORDER BY LOAD_DTS ))=1 ),
SRC_SINVLNWINN    as ( SELECT BKCC, DISTRIBUTION_CHANNEL_BK, DISTRIBUTION_CHANNEL_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_sales_invoice_line__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY DISTRIBUTION_CHANNEL_BK ORDER BY LOAD_DTS ))=1 )

/*
SRC_s              as ( SELECT * FROM STAGING.V_PSA_STG_DISTRIBUTION_CHANNEL__WINN_SAP )
SRC_knvv           as ( SELECT * FROM STAGING.V_PSA_STG_CUSTOMER_SALES_MASTER__WINN_SAP )
SRC_a              as ( SELECT * FROM STAGING.v_psa_stg_goods_movement_storage_location__winn_sap )
SRC_ce1new4        as ( SELECT * FROM STAGING.v_psa_stg_copa_sales__winn_sap )
SRC_azcopa         as ( SELECT * FROM STAGING.v_psa_stg_copa_sales_history__winn_sap )
SRC_hofrsales      as ( SELECT * FROM STAGING.v_psa_stg_legacy_hofrus_sales__hofr_ecl )
SRC_zservlevel     as ( SELECT * FROM STAGING.v_psa_stg_service_levels__winn_sap )
SRC_demand    as ( SELECT * FROM STAGING.v_psa_stg_demand_planning__winn_sap )
SRC_demand_2    as ( SELECT * FROM STAGING.v_psa_stg_demand_planning_history__winn_sap )
SRC_SOL            as ( SELECT * FROM STAGING.v_psa_stg_order_item__winn_sap )
SRC_SINVLNWINN    as ( SELECT * FROM STAGING.v_psa_stg_sales_invoice_line__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_s as (
    SELECT
        DISTRIBUTION_CHANNEL_HK
      , DISTRIBUTION_CHANNEL_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_s
)

, LOGIC_knvv as (
    SELECT
        DISTRIBUTION_CHANNEL_HK
      , DISTRIBUTION_CHANNEL_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_knvv
)

, LOGIC_a as (
    SELECT
        DISTRIBUTION_CHANNEL_HK
      , DISTRIBUTION_CHANNEL_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_a
)

, LOGIC_ce1new4 as (
    SELECT
        DISTRIBUTION_CHANNEL_HK
      , DISTRIBUTION_CHANNEL_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ce1new4
)

, LOGIC_azcopa as (
    SELECT
        DISTRIBUTION_CHANNEL_HK
      , DISTRIBUTION_CHANNEL_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_azcopa
)

, LOGIC_hofrsales as (
    SELECT
        DISTRIBUTION_CHANNEL_HK
      , DISTRIBUTION_CHANNEL_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_hofrsales
)

, LOGIC_zservlevel as (
    SELECT
        DISTRIBUTION_CHANNEL_HK
      , DISTRIBUTION_CHANNEL_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_zservlevel
)

, LOGIC_demand as (
    SELECT
        DISTRIBUTION_CHANNEL_HK
      , DISTRIBUTION_CHANNEL_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_demand
)

, LOGIC_demand_2 as (
    SELECT
        DISTRIBUTION_CHANNEL_HK
      , DISTRIBUTION_CHANNEL_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_demand_2
)

, LOGIC_SOL as (
    SELECT
        DISTRIBUTION_CHANNEL_HK
      , DISTRIBUTION_CHANNEL_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SOL
)

, LOGIC_SINVLNWINN as (
    SELECT
        DISTRIBUTION_CHANNEL_HK
      , DISTRIBUTION_CHANNEL_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SINVLNWINN
)
---- RENAME LAYER ----

, RENAME_s as (
    SELECT
        DISTRIBUTION_CHANNEL_HK
      , DISTRIBUTION_CHANNEL_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_s
)

, RENAME_knvv as (
    SELECT
        DISTRIBUTION_CHANNEL_HK
      , DISTRIBUTION_CHANNEL_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_knvv
)

, RENAME_a as (
    SELECT
        DISTRIBUTION_CHANNEL_HK
      , DISTRIBUTION_CHANNEL_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_a
)

, RENAME_ce1new4 as (
    SELECT
        DISTRIBUTION_CHANNEL_HK
      , DISTRIBUTION_CHANNEL_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ce1new4
)

, RENAME_azcopa as (
    SELECT
        DISTRIBUTION_CHANNEL_HK
      , DISTRIBUTION_CHANNEL_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_azcopa
)

, RENAME_hofrsales as (
    SELECT
        DISTRIBUTION_CHANNEL_HK
      , DISTRIBUTION_CHANNEL_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_hofrsales
)

, RENAME_zservlevel as (
    SELECT
        DISTRIBUTION_CHANNEL_HK
      , DISTRIBUTION_CHANNEL_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_zservlevel
)

, RENAME_demand as (
    SELECT
        DISTRIBUTION_CHANNEL_HK
      , DISTRIBUTION_CHANNEL_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_demand
)

, RENAME_demand_2 as (
    SELECT
        DISTRIBUTION_CHANNEL_HK
      , DISTRIBUTION_CHANNEL_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_demand_2
)

, RENAME_SOL as (
    SELECT
        DISTRIBUTION_CHANNEL_HK
      , DISTRIBUTION_CHANNEL_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SOL
)

, RENAME_SINVLNWINN as (
    SELECT
        DISTRIBUTION_CHANNEL_HK
      , DISTRIBUTION_CHANNEL_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SINVLNWINN
)
---- FILTER LAYER ----

, FILTER_s as (
    SELECT *
    FROM RENAME_s
)

, FILTER_knvv as (
    SELECT *
    FROM RENAME_knvv
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

, FILTER_ce1new4 as (
    SELECT *
    FROM RENAME_ce1new4
)

, FILTER_azcopa as (
    SELECT *
    FROM RENAME_azcopa
)

, FILTER_hofrsales as (
    SELECT *
    FROM RENAME_hofrsales
)

, FILTER_zservlevel as (
    SELECT *
    FROM RENAME_zservlevel
)

, FILTER_demand as (
    SELECT *
    FROM RENAME_demand
)

, FILTER_demand_2 as (
    SELECT *
    FROM RENAME_demand_2
)

, FILTER_SOL as (
    SELECT *
    FROM RENAME_SOL
)

, FILTER_SINVLNWINN as (
    SELECT *
    FROM RENAME_SINVLNWINN
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_s
    UNION ALL
    SELECT * FROM FILTER_knvv
    UNION ALL
    SELECT *
    FROM FILTER_a  
    UNION ALL
    SELECT * FROM FILTER_ce1new4
    UNION ALL
    SELECT * FROM FILTER_azcopa   
    UNION ALL
    SELECT * FROM FILTER_hofrsales
    UNION ALL
    SELECT * FROM FILTER_zservlevel
    UNION ALL
    SELECT * FROM FILTER_demand
    UNION ALL
    SELECT * FROM FILTER_demand_2
    UNION ALL
    SELECT * FROM FILTER_SOL
    UNION ALL
    SELECT * FROM FILTER_SINVLNWINN
)

---- FINAL LAYER ----
SELECT
          DISTRIBUTION_CHANNEL_HK
        , DISTRIBUTION_CHANNEL_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.DISTRIBUTION_CHANNEL_HK = JOIN_RESULT.DISTRIBUTION_CHANNEL_HK
)
{% endif %}
/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per BKs and BKCC. */
qualify 1 = row_number() over (partition by DISTRIBUTION_CHANNEL_BK, BKCC order by LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS DISTRIBUTION_CHANNEL_HK,
GR.VALUE::text AS DISTRIBUTION_CHANNEL_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
