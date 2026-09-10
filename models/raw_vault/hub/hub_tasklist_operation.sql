---- SRC LAYER ----
WITH
SRC_OPWINN         as ( SELECT BKCC, LOAD_DTS, REC_SRC, TASKLIST_OPERATION_BK, TASKLIST_OPERATION_HK FROM {{ ref('v_psa_stg_tasklist_operation__winn_sap') }} as SRC  ),
SRC_OPGWINN        as ( SELECT BKCC, LOAD_DTS, REC_SRC, TASKLIST_OPERATION_BK, TASKLIST_OPERATION_HK FROM {{ ref('v_psa_stg_tasklist_group_operation__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY TASKLIST_OPERATION_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_OPWINN         as ( SELECT * FROM STAGING.v_psa_stg_tasklist_operation__winn_sap )
SRC_OPGWINN        as ( SELECT * FROM STAGING.v_psa_stg_tasklist_group_operation__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_OPWINN as (
    SELECT
        TASKLIST_OPERATION_HK
      , TASKLIST_OPERATION_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_OPWINN
)

, LOGIC_OPGWINN as (
    SELECT
        TASKLIST_OPERATION_HK
      , TASKLIST_OPERATION_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_OPGWINN
)
---- RENAME LAYER ----

, RENAME_OPWINN as (
    SELECT
        TASKLIST_OPERATION_HK
      , TASKLIST_OPERATION_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_OPWINN
)

, RENAME_OPGWINN as (
    SELECT
        TASKLIST_OPERATION_HK
      , TASKLIST_OPERATION_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_OPGWINN
)
---- FILTER LAYER ----

, FILTER_OPWINN as (
    SELECT *
    FROM RENAME_OPWINN
)

, FILTER_OPGWINN as (
    SELECT *
    FROM RENAME_OPGWINN
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_OPWINN
    UNION ALL
    SELECT * FROM FILTER_OPGWINN
)

---- FINAL LAYER ----
SELECT
          TASKLIST_OPERATION_HK
        , TASKLIST_OPERATION_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
 WHERE NOT EXISTS (
  SELECT 1 
  FROM {{ this }} existing
  WHERE existing.TASKLIST_OPERATION_HK= JOIN_RESULT.TASKLIST_OPERATION_HK
 )
 {% endif %}
 /* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per BKs and BKCC. */
 qualify 1 = row_number() over (partition by TASKLIST_OPERATION_HK order by LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS TASKLIST_OPERATION_HK,
GR.VALUE::text AS TASKLIST_OPERATION_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}

