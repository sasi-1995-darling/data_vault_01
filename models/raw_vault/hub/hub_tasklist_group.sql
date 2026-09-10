---- SRC LAYER ----
WITH
SRC_TGWINN         as ( SELECT BKCC, LOAD_DTS, REC_SRC, TASKLIST_GROUP_BK, TASKLIST_GROUP_HK FROM {{ ref('v_psa_stg_tasklist_group__winn_sap') }} as SRC  ),
SRC_TGOPWINN       as ( SELECT BKCC, LOAD_DTS, REC_SRC, TASKLIST_GROUP_BK, TASKLIST_GROUP_HK FROM {{ ref('v_psa_stg_tasklist_group_operation__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY TASKLIST_GROUP_HK ORDER BY LOAD_DTS ))=1 ),
SRC_TAWINN         as ( SELECT BKCC, LOAD_DTS, REC_SRC, TASKLIST_GROUP_BK, TASKLIST_GROUP_HK FROM {{ ref('v_psa_stg_tasklist_assignment__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY TASKLIST_GROUP_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_TGWINN         as ( SELECT * FROM STAGING.v_psa_stg_tasklist_group__winn_sap )
SRC_TGOPWINN       as ( SELECT * FROM STAGING.v_psa_stg_tasklist_group_operation__winn_sap )
SRC_TAWINN         as ( SELECT * FROM STAGING.v_psa_stg_tasklist_assignment__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_TGWINN as (
    SELECT
        TASKLIST_GROUP_HK
      , TASKLIST_GROUP_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_TGWINN
)

, LOGIC_TGOPWINN as (
    SELECT
        TASKLIST_GROUP_HK
      , TASKLIST_GROUP_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_TGOPWINN
)

, LOGIC_TAWINN as (
    SELECT
        TASKLIST_GROUP_HK
      , TASKLIST_GROUP_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_TAWINN
)
---- RENAME LAYER ----

, RENAME_TGWINN as (
    SELECT
        TASKLIST_GROUP_HK
      , TASKLIST_GROUP_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_TGWINN
)

, RENAME_TGOPWINN as (
    SELECT
        TASKLIST_GROUP_HK
      , TASKLIST_GROUP_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_TGOPWINN
)

, RENAME_TAWINN as (
    SELECT
        TASKLIST_GROUP_HK
      , TASKLIST_GROUP_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_TAWINN
)
---- FILTER LAYER ----

, FILTER_TGWINN as (
    SELECT *
    FROM RENAME_TGWINN
)

, FILTER_TGOPWINN as (
    SELECT *
    FROM RENAME_TGOPWINN
)

, FILTER_TAWINN as (
    SELECT *
    FROM RENAME_TAWINN
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_TGWINN
    UNION ALL
    SELECT * FROM FILTER_TGOPWINN
    UNION ALL
    SELECT * FROM FILTER_TAWINN
)

---- FINAL LAYER ----
SELECT
          TASKLIST_GROUP_HK
        , TASKLIST_GROUP_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
 WHERE NOT EXISTS (
  SELECT 1 
  FROM {{ this }} existing
  WHERE existing.TASKLIST_GROUP_HK= JOIN_RESULT.TASKLIST_GROUP_HK
 )
 {% endif %}
 /* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per BKs and BKCC. */
 qualify 1 = row_number() over (partition by TASKLIST_GROUP_HK order by LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS TASKLIST_GROUP_HK,
GR.VALUE::text AS TASKLIST_GROUP_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}

