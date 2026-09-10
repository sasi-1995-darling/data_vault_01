---- SRC LAYER ----
WITH
SRC_t024           as ( SELECT * FROM {{ ref('v_psa_stg_purchasing_org__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   )

/*
SRC_t024           as ( SELECT * FROM staging.v_psa_stg_purchasing_org__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_t024 as (
    SELECT
        PURCHASING_ORG_HK
      , EKGRP
      , LOAD_DTS
      , MANDT
      , EKNAM
      , EKTEL
      , LDEST
      , TELFX
      , TEL_NUMBER
      , TEL_EXTENS
      , SMTP_ADDR
      , ERNAM
      , MSNAM
      , ZZTMCHG
      , ZZMATNR
      , ZNEWMTW
      , ZCOREMTW
      , MNCOD
      , GLDELFLAG
      , GLCHANGETIME
      , GLREQUEST
      , GLSOURCESYSTEM
      , GLCHANGETIME_DTTM
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_t024
)
---- RENAME LAYER ----

, RENAME_t024 as (
    SELECT
        PURCHASING_ORG_HK
      , EKGRP
      , LOAD_DTS
      , MANDT
      , EKNAM
      , EKTEL
      , LDEST
      , TELFX
      , TEL_NUMBER
      , TEL_EXTENS
      , SMTP_ADDR
      , ERNAM
      , MSNAM
      , ZZTMCHG
      , ZZMATNR
      , ZNEWMTW
      , ZCOREMTW
      , MNCOD
      , GLDELFLAG
      , GLCHANGETIME
      , GLREQUEST
      , GLSOURCESYSTEM
      , GLCHANGETIME_DTTM
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_t024
)
---- FILTER LAYER ----

, FILTER_t024 as (
    SELECT *
    FROM RENAME_t024
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_t024
)

---- FINAL LAYER ----
SELECT
          PURCHASING_ORG_HK
        , EKGRP
        , LOAD_DTS
        , MANDT
        , EKNAM
        , EKTEL
        , LDEST
        , TELFX
        , TEL_NUMBER
        , TEL_EXTENS
        , SMTP_ADDR
        , ERNAM
        , MSNAM
        , ZZTMCHG
        , ZZMATNR
        , ZNEWMTW
        , ZCOREMTW
        , MNCOD
        , GLDELFLAG
        , GLCHANGETIME
        , GLREQUEST
        , GLSOURCESYSTEM
        , GLCHANGETIME_DTTM
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT

{% if is_incremental() %}


WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PURCHASING_ORG_HK = JOIN_RESULT.PURCHASING_ORG_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1= row_number()over(partition by PURCHASING_ORG_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT
         MD5_BINARY(GR.VALUE) AS PURCHASING_ORG_HK
		 , GR.VALUE AS EKGRP
        , CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS

, NULL AS MANDT
, NULL AS EKNAM
, NULL AS EKTEL
, NULL AS LDEST
, NULL AS TELFX
, NULL AS TEL_NUMBER
, NULL AS TEL_EXTENS
, NULL AS SMTP_ADDR
, NULL AS ERNAM
, NULL AS MSNAM
, NULL AS ZZTMCHG
, NULL AS ZZMATNR
, NULL AS ZNEWMTW
, NULL AS ZCOREMTW
, NULL AS MNCOD
, NULL AS GLDELFLAG
, NULL AS GLCHANGETIME
, NULL AS GLREQUEST
, NULL AS GLSOURCESYSTEM
, NULL AS GLCHANGETIME_DTTM
, '1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS
, 'N' AS PSA_DELETE_IND
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, ''::BINARY as HASH_DIFF
        FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

    {% endif %}