---- SRC LAYER ----
WITH
SRC_GLUSR          as ( SELECT BKCC, LOAD_DTS, REC_SRC, USER_NAME_BK, USER_NAME_HK FROM {{ ref('v_psa_stg_gl_user__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY USER_NAME_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_GLUSR          as ( SELECT * FROM STAGING.v_psa_stg_gl_user__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_GLUSR as (
    SELECT
        USER_NAME_HK
      , USER_NAME_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_GLUSR
)
---- RENAME LAYER ----

, RENAME_GLUSR as (
    SELECT
        USER_NAME_HK
      , USER_NAME_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_GLUSR
)
---- FILTER LAYER ----

, FILTER_GLUSR as (
    SELECT *
    FROM RENAME_GLUSR
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_GLUSR
)

---- FINAL LAYER ----
SELECT
          USER_NAME_HK
        , USER_NAME_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.USER_NAME_HK= JOIN_RESULT.USER_NAME_HK
)
{% endif %}

{% if not is_incremental() %}
 union all
 
 SELECT MD5_BINARY(GR.VALUE) USER_NAME_HK
 , GR.VALUE AS USER_NAME_BK
 , DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC
 , CONVERT_TIMEZONE('UTC','1900-01-01') AS LOAD_DTS
 , 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
 FROM
 TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
 {% endif %}