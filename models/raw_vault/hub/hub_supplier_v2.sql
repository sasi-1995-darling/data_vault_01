---- SRC LAYER ----
WITH
SRC_SML            as ( SELECT BKCC, LOAD_DTS, REC_SRC, SUPPLIER_BK, SUPPLIER_HK FROM {{ ref('v_psa_stg_supplier__ml_ebs') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS ))=1 ),
SRC_SWINN          as ( SELECT BKCC, LOAD_DTS, REC_SRC, SUPPLIER_BK, SUPPLIER_HK FROM {{ ref('v_psa_stg_supplier__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS ))=1 ),
SRC_MDM            as ( SELECT BKCC, LOAD_DTS, REC_SRC, SUPPLIER_BK, SUPPLIER_HK FROM {{ ref('v_psa_stg_supplier_mdm') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS ))=1 ),
SRC_GP             as ( SELECT BKCC, LOAD_DTS, REC_SRC, SUPPLIER_BK, SUPPLIER_HK FROM {{ ref('v_psa_stg_supplier__tt_gp') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS ))=1 ),
SRC_E21            as ( SELECT BKCC, LOAD_DTS, REC_SRC, SUPPLIER_BK, SUPPLIER_HK FROM {{ ref('v_psa_stg_supplier__tt_e21') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS ))=1 ),
SRC_LRSN           as ( SELECT BKCC, LOAD_DTS, REC_SRC, SUPPLIER_BK, SUPPLIER_HK FROM {{ ref('v_psa_stg_supplier__lrsn_psft') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS ))=1 ),
SRC_EMTK           as ( SELECT BKCC, LOAD_DTS, REC_SRC, SUPPLIER_BK, SUPPLIER_HK FROM {{ ref('v_psa_stg_supplier__emtk_ebs') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS ))=1 ),
SRC_MRPLINE        as ( SELECT BKCC, LOAD_DTS, REC_SRC, SUPPLIER_BK, SUPPLIER_HK FROM {{ ref('v_psa_stg_mrp_lines__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS ))=1 ),
SRC_INVENTORY      as ( SELECT BKCC, LOAD_DTS, REC_SRC, SUPPLIER_BK, SUPPLIER_HK FROM {{ ref('v_psa_stg_goods_movement__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS ))=1 ),
SRC_t001l          as ( SELECT BKCC, LOAD_DTS, REC_SRC, SUPPLIER_BK, SUPPLIER_HK FROM {{ ref('v_psa_stg_goods_movement_storage_location__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS ))=1 ),
SRC_FIB            as ( SELECT BKCC, LOAD_DTS, REC_SRC, SUPPLIER_BK, SUPPLIER_HK FROM {{ ref('v_psa_stg_supplier__fib_ocf') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PURRCRDWINN            as ( SELECT BKCC, LOAD_DTS, REC_SRC, SUPPLIER_BK, SUPPLIER_HK FROM {{ ref('v_psa_stg_purchasing_records__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_SML            as ( SELECT * FROM STAGING.v_psa_stg_supplier__ml_ebs )
SRC_SWINN          as ( SELECT * FROM STAGING.v_psa_stg_supplier__winn_sap )
SRC_MDM            as ( SELECT * FROM STAGING.v_psa_stg_supplier_mdm )
SRC_GP             as ( SELECT * FROM STAGING.v_psa_stg_supplier__tt_gp )
SRC_E21            as ( SELECT * FROM STAGING.v_psa_stg_supplier__tt_e21 )
SRC_LRSN           as ( SELECT * FROM STAGING.v_psa_stg_supplier__lrsn_psft )
SRC_EMTK           as ( SELECT * FROM STAGING.v_psa_stg_supplier__emtk_ebs )
SRC_MRPLINE        as ( SELECT * FROM STAGING.v_psa_stg_mrp_lines__winn_sap )
SRC_INVENTORY      as ( SELECT * FROM STAGING.v_psa_stg_goods_movement__winn_sap )
SRC_t001l          as ( SELECT * FROM STAGING.v_psa_stg_goods_movement_storage_location__winn_sap )
SRC_FIB            as ( SELECT * FROM STAGING.v_psa_stg_supplier__fib_ocf )
SRC_PURRCRDWINN    as ( SELECT * FROM STAGING.v_psa_stg_purchasing_records__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_SML as (
    SELECT
        SUPPLIER_HK
      , SUPPLIER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SML
)

, LOGIC_SWINN as (
    SELECT
        SUPPLIER_HK
      , SUPPLIER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SWINN
)

, LOGIC_MDM as (
    SELECT
        SUPPLIER_HK
      , SUPPLIER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_MDM
)

, LOGIC_GP as (
    SELECT
        SUPPLIER_HK
      , SUPPLIER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_GP
)

, LOGIC_E21 as (
    SELECT
        SUPPLIER_HK
      , SUPPLIER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_E21
)

, LOGIC_LRSN as (
    SELECT
        SUPPLIER_HK
      , SUPPLIER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_LRSN
)

, LOGIC_EMTK as (
    SELECT
        SUPPLIER_HK
      , SUPPLIER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_EMTK
)

, LOGIC_MRPLINE as (
    SELECT
        SUPPLIER_HK
      , SUPPLIER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_MRPLINE
)

, LOGIC_INVENTORY as (
    SELECT
        SUPPLIER_HK
      , SUPPLIER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_INVENTORY
)

, LOGIC_t001l as (
    SELECT
        SUPPLIER_HK
      , SUPPLIER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_t001l
)

, LOGIC_FIB as (
    SELECT
        SUPPLIER_HK
      , SUPPLIER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_FIB
)

, LOGIC_PURRCRDWINN as (
    SELECT
        SUPPLIER_HK
      , SUPPLIER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PURRCRDWINN
)
---- RENAME LAYER ----

, RENAME_SML as (
    SELECT
        SUPPLIER_HK
      , SUPPLIER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SML
)

, RENAME_SWINN as (
    SELECT
        SUPPLIER_HK
      , SUPPLIER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SWINN
)

, RENAME_MDM as (
    SELECT
        SUPPLIER_HK
      , SUPPLIER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_MDM
)

, RENAME_GP as (
    SELECT
        SUPPLIER_HK
      , SUPPLIER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_GP
)

, RENAME_E21 as (
    SELECT
        SUPPLIER_HK
      , SUPPLIER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_E21
)

, RENAME_LRSN as (
    SELECT
        SUPPLIER_HK
      , SUPPLIER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_LRSN
)

, RENAME_EMTK as (
    SELECT
        SUPPLIER_HK
      , SUPPLIER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_EMTK
)

, RENAME_MRPLINE as (
    SELECT
        SUPPLIER_HK
      , SUPPLIER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_MRPLINE
)

, RENAME_INVENTORY as (
    SELECT
        SUPPLIER_HK
      , SUPPLIER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_INVENTORY
)

, RENAME_t001l as (
    SELECT
        SUPPLIER_HK
      , SUPPLIER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_t001l
)

, RENAME_FIB as (
    SELECT
        SUPPLIER_HK
      , SUPPLIER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_FIB
)

, RENAME_PURRCRDWINN as (
    SELECT
        SUPPLIER_HK
      , SUPPLIER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PURRCRDWINN
)
---- FILTER LAYER ----

, FILTER_SML as (
    SELECT *
    FROM RENAME_SML
)

, FILTER_SWINN as (
    SELECT *
    FROM RENAME_SWINN
)

, FILTER_MDM as (
    SELECT *
    FROM RENAME_MDM
)

, FILTER_GP as (
    SELECT *
    FROM RENAME_GP
)

, FILTER_E21 as (
    SELECT *
    FROM RENAME_E21
)

, FILTER_LRSN as (
    SELECT *
    FROM RENAME_LRSN
)

, FILTER_EMTK as (
    SELECT *
    FROM RENAME_EMTK
)

, FILTER_MRPLINE as (
    SELECT *
    FROM RENAME_MRPLINE
)

, FILTER_INVENTORY as (
    SELECT *
    FROM RENAME_INVENTORY
)

, FILTER_t001l as (
    SELECT *
    FROM RENAME_t001l
)

, FILTER_FIB as (
    SELECT *
    FROM RENAME_FIB
)

, FILTER_PURRCRDWINN as (
    SELECT *
    FROM RENAME_PURRCRDWINN
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_SML
    UNION ALL
    SELECT * FROM FILTER_SWINN
    UNION ALL
    SELECT * FROM FILTER_MDM
    UNION ALL
    SELECT * FROM FILTER_GP
    UNION ALL
    SELECT * FROM FILTER_E21
    UNION ALL
    SELECT * FROM FILTER_LRSN
    UNION ALL
    SELECT * FROM FILTER_EMTK
    UNION ALL
    SELECT * FROM FILTER_MRPLINE
    UNION ALL
    SELECT * FROM FILTER_INVENTORY
    UNION ALL
    SELECT * FROM FILTER_t001l
    UNION ALL
    SELECT * FROM FILTER_FIB
    UNION ALL
    SELECT * FROM FILTER_PURRCRDWINN
)

---- FINAL LAYER ----
SELECT
          SUPPLIER_HK
        , SUPPLIER_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.SUPPLIER_HK = JOIN_RESULT.SUPPLIER_HK
)
{% endif %}
QUALIFY 1= ROW_NUMBER() OVER (PARTITION BY SUPPLIER_BK, BKCC ORDER BY LOAD_DTS)                                                                                              {% if not is_incremental() %}
union all
SELECT MD5_BINARY(GR.VALUE)  SUPPLIER_HK
, GR.VALUE  AS SUPPLIER_BK
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
