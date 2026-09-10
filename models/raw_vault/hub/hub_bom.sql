---- SRC LAYER ----
WITH
SRC_boms           as ( SELECT * FROM {{ ref('v_psa_stg_bom_component_selection__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY BOM_HK ORDER BY LOAD_DTS ))=1 ),
SRC_bomp           as ( SELECT * FROM {{ ref('v_psa_stg_bom_permanent__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY BOM_HK ORDER BY LOAD_DTS ))=1 ),
SRC_bomh           as ( SELECT * FROM {{ ref('v_psa_stg_bom_header__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY BOM_HK ORDER BY LOAD_DTS ))=1 ),
SRC_bombpi         as ( SELECT * FROM {{ ref('v_psa_stg_bom_plant_item__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY BOM_HK ORDER BY LOAD_DTS ))=1 ),
SRC_bombci         as ( SELECT * FROM {{ ref('v_psa_stg_bom_component_item__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY BOM_HK ORDER BY LOAD_DTS ))=1 ),
SRC_bomst          as ( SELECT * FROM {{ ref('v_psa_stg_bom_structures__ml_ebs') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY BOM_HK ORDER BY LOAD_DTS ))=1 ),
SRC_bomc           as ( SELECT * FROM {{ ref('v_psa_stg_bom_components__ml_ebs') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY BOM_HK ORDER BY LOAD_DTS ))=1 ),
SRC_reservation    as ( SELECT * FROM {{ ref('v_psa_stg_reservation_line__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY BOM_BK ORDER BY LOAD_DTS ))=1 ),
SRC_PROD_ORDER     as ( SELECT  BOM_HK, BOM_BK, BKCC, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_production_order_header__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY BOM_BK ORDER BY LOAD_DTS ))=1 ),
SRC_TASKLIST_GROUP     as ( SELECT  BOM_HK, BOM_BK, BKCC, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_tasklist_group__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY BOM_BK ORDER BY LOAD_DTS ))=1 )

/*
SRC_boms           as ( SELECT * FROM STAGING.V_PSA_STG_BOM_COMPONENT_SELECTION__WINN_SAP )
, SRC_bomp         as ( SELECT * FROM STAGING.V_PSA_STG_BOM_PERMANENT__WINN_SAP )
, SRC_bomh         as ( SELECT * FROM STAGING.V_PSA_STG_BOM_HEADER__WINN_SAP )
, SRC_bombpi       as ( SELECT * FROM STAGING.V_PSA_STG_BOM_PLANT_ITEM__WINN_SAP )
, SRC_bombci       as ( SELECT * FROM STAGING.V_PSA_STG_BOM_COMPONENT_ITEM__WINN_SAP )
, SRC_bomst        as ( SELECT * FROM STAGING.V_PSA_STG_BOM_STRUCTURES__ML_EBS )
, SRC_bomc         as ( SELECT * FROM STAGING.V_PSA_STG_BOM_COMPONENTS__ML_EBS )
, SRC_reservation  as ( SELECT * FROM STAGING.v_psa_stg_reservation_line__winn_sap )
, SRC_PROD_ORDER   as ( SELECT * FROM STAGING.v_psa_stg_production_order_header__winn_sap )
, SRC_PROD_ORDER   as ( SELECT * FROM STAGING.v_psa_stg_tasklist_group__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_boms as (
    SELECT
        BOM_HK
      , BOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_boms
)

, LOGIC_bomp as (
    SELECT
        BOM_HK
      , BOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_bomp
)

, LOGIC_bomh as (
    SELECT
        BOM_HK
      , BOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_bomh
)

, LOGIC_bombci as (
    SELECT
        BOM_HK
      , BOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_bombci
)

, LOGIC_bombpi as (
    SELECT
        BOM_HK
      , BOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_bombpi
)

, LOGIC_bomst as (
    SELECT
        BOM_HK
      , BOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_bomst
)

, LOGIC_bomc as (
    SELECT
        BOM_HK
      , BOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_bomc
)

, LOGIC_reservation as (
    SELECT
        BOM_HK
      , BOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_reservation
)

, LOGIC_PROD_ORDER as (
    SELECT
        BOM_HK
      , BOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PROD_ORDER
)

, LOGIC_TASKLIST_GROUP as (
    SELECT
        BOM_HK
      , BOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_TASKLIST_GROUP
)
---- RENAME LAYER ----

, RENAME_boms as (
    SELECT
        BOM_HK
      , BOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_boms
)

, RENAME_bomp as (
    SELECT
        BOM_HK
      , BOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_bomp
)

, RENAME_bomh as (
    SELECT
        BOM_HK
      , BOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_bomh
)

, RENAME_bombci as (
    SELECT
        BOM_HK
      , BOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_bombci
)

, RENAME_bombpi as (
    SELECT
        BOM_HK
      , BOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_bombpi
)

, RENAME_bomst as (
    SELECT
        BOM_HK
      , BOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_bomst
)

, RENAME_bomc as (
    SELECT
        BOM_HK
      , BOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_bomc
)

, RENAME_reservation as (
    SELECT
        BOM_HK
      , BOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_reservation
)

, RENAME_PROD_ORDER as (
    SELECT
        BOM_HK
      , BOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PROD_ORDER
)

, RENAME_TASLIST_GROUP as (
    SELECT
        BOM_HK
      , BOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_TASKLIST_GROUP
)
---- FILTER LAYER ----

, FILTER_boms as (
    SELECT *
    FROM RENAME_boms
)

, FILTER_bomp as (
    SELECT *
    FROM RENAME_bomp
)

, FILTER_bomh as (
    SELECT *
    FROM RENAME_bomh
)

, FILTER_bombci as (
    SELECT *
    FROM RENAME_bombci
)

, FILTER_bombpi as (
    SELECT *
    FROM RENAME_bombpi
)

, FILTER_bomst as (
    SELECT *
    FROM RENAME_bomst
)

, FILTER_bomc as (
    SELECT *
    FROM RENAME_bomc
)

, FILTER_reservation as (
    SELECT *
    FROM RENAME_reservation
)

, FILTER_PROD_ORDER as (
    SELECT *
    FROM RENAME_PROD_ORDER
)

, FILTER_TASLIST_GROUP as (
    SELECT *
    FROM RENAME_TASLIST_GROUP
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_boms
    UNION ALL
    SELECT * FROM FILTER_bomp
    UNION ALL
    SELECT * FROM FILTER_bomh
    UNION ALL
    SELECT * FROM FILTER_bombpi
    UNION ALL
    SELECT * FROM FILTER_bombci
    UNION ALL
    SELECT * FROM FILTER_bomst
    UNION ALL
    SELECT * FROM FILTER_bomc   
    UNION ALL
    SELECT * FROM FILTER_reservation 
    UNION ALL
    SELECT * FROM FILTER_PROD_ORDER
    UNION ALL
    SELECT * FROM FILTER_TASLIST_GROUP
)

---- FINAL LAYER ----
SELECT
          BOM_HK
        , BOM_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.BOM_HK = JOIN_RESULT.BOM_HK
)
{% endif %}
QUALIFY 1= ROW_NUMBER() OVER (PARTITION BY BOM_HK ORDER BY LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS BOM_HK,
GR.VALUE::text AS BOM_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}